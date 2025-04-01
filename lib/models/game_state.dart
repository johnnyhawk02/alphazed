import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_item.dart';
import '../services/audio_service.dart';
import '../services/asset_loader.dart';
// Ensure GameConfig is imported if needed for generateOptions or elsewhere
// import '../config/game_config.dart';
import 'package:flutter/widgets.dart';

class GameState extends ChangeNotifier {
  final AudioService audioService;
  List<GameItem> gameItems = [];
  final List<String> allLetters = List.generate(26, (index) => String.fromCharCode(97 + index));
  int currentIndex = 0;
  int questionVariation = 1;
  final Random random = Random();

  // --- State for Cycling Celebrations ---
  int _nextCelebrationScreenIndex = 0;

  // Set to track words for which questions have already been played
  final Set<String> _playedQuestions = {};

  // Property to store the next prepared item (if needed for more complex preloading)
  // GameItem? _preparedItem; // Currently unused based on flow, can be removed if not needed

  // Public method to check if a word has had its question played
  bool hasQuestionBeenPlayed(String word) {
    return _playedQuestions.contains(word.toLowerCase());
  }

  // Public method to mark a word as having had its question played
  void markQuestionAsPlayed(String word) {
    _playedQuestions.add(word.toLowerCase());
  }

  bool isQuestionPlaying = false; // May not be needed if audio service handles state
  int visibleLetterCount = 0;
  int coloredLetterCount = 0;
  bool lettersAreDraggable = false;
  bool isImageVisible = false;
  List<String> currentOptions = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Property to control whether game has fully started
  bool _gameStarted = false;
  bool get gameStarted => _gameStarted;

  GameItem? get currentItem => gameItems.isEmpty || currentIndex >= gameItems.length ? null : gameItems[currentIndex];

  // --- Method to get the next celebration index and increment for next time ---
  int getAndIncrementNextCelebrationIndex(int totalScreens) {
    if (totalScreens <= 0) return 0; // Avoid division by zero
    final indexToShow = _nextCelebrationScreenIndex;
    _nextCelebrationScreenIndex = (_nextCelebrationScreenIndex + 1) % totalScreens;
    print("Next celebration index: $_nextCelebrationScreenIndex (was $indexToShow)"); // Added logging
    return indexToShow;
  }

  GameState({required this.audioService}) {
    // Removed the onCongratsStart callback assignment
    // audioService.onCongratsStart = hideLetters;
  }

  Future<void> loadGameItems() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final imageFiles = await AssetLoader.getAssets(
        directory: 'images/words',
        extensions: ['.jpeg', '.jpg', '.png']
      );

      if (imageFiles.isEmpty) {
        print("Warning: No image files found in assets/images/words. Loading defaults.");
        _loadDefaultItems();
      } else {
        gameItems = imageFiles.map((path) => GameItem.fromImagePath(path)).toList();
        gameItems.shuffle(random);
      }

      if (gameItems.isNotEmpty) {
        currentIndex = 0; // Ensure we start at the beginning
        currentOptions = gameItems[currentIndex].generateOptions(allLetters);
        // Initial state before game starts (image not visible, buttons not active)
        visibleLetterCount = currentOptions.length; // Prepare count
        coloredLetterCount = 0;
        lettersAreDraggable = false;
        isImageVisible = false;
        _gameStarted = false; // Ensure game hasn't started yet
        _playedQuestions.clear(); // Clear played questions on new load
      } else {
        print("Error: No game items loaded, including defaults.");
        currentOptions = [];
        visibleLetterCount = 0;
        coloredLetterCount = 0;
        lettersAreDraggable = false;
        isImageVisible = false;
      }

    } catch (e) {
      print("Error loading game items: $e");
       print("Attempting to load default items due to error.");
      _loadDefaultItems(); // Attempt to load defaults on error
      if (gameItems.isNotEmpty) {
         currentIndex = 0;
         currentOptions = gameItems[currentIndex].generateOptions(allLetters);
         visibleLetterCount = currentOptions.length;
         coloredLetterCount = 0;
         lettersAreDraggable = false;
         isImageVisible = false;
         _gameStarted = false;
         _playedQuestions.clear();
      } else {
        print("Error: Failed to load default items as well.");
        currentOptions = [];
        visibleLetterCount = 0;
        // Handle case where even defaults fail (e.g., show error message)
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to load default items if asset loading fails or finds nothing
  void _loadDefaultItems() {
    // Define paths relative to assets folder
    final defaults = [
      'assets/images/words/apple.jpeg',
      'assets/images/words/ball.jpeg',
      'assets/images/words/cat.jpeg',
      // Add more defaults if desired
    ];

    try {
       gameItems = defaults.map((path) => GameItem.fromImagePath(path)).toList();
       print("Loaded ${gameItems.length} default items.");
    } catch (e) {
       print("Error creating GameItem from default path: $e");
       gameItems = []; // Ensure list is empty if defaults fail
    }
    // Note: notifyListeners() is called in the finally block of loadGameItems
  }

  // Call this method when the user explicitly starts the game (e.g., taps a start button)
  Future<void> startGame() async {
    if (_gameStarted || gameItems.isEmpty || isLoading) return; // Prevent multiple starts or starting without items

    print("Starting game...");
    _gameStarted = true;
    isImageVisible = true; // Show the first image

    // Make the initial set of buttons visible and active
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = currentOptions.length;
    lettersAreDraggable = true;

    notifyListeners();

    // Note: Question audio is triggered by the screen based on image visibility and played status
  }


  // Method to prepare the *next* item's data (e.g., for precaching image)
  // Returns the path of the next image if available.
  Future<String?> prepareNextImage() async {
    if (gameItems.isEmpty) return null;

    int nextIndex = (currentIndex + 1) % gameItems.length;

    // Validate the image path before returning it
    final imagePath = gameItems[nextIndex].imagePath;
    
    try {
      // Basic path validation
      if (imagePath.isEmpty) {
        print("WARNING: Empty image path detected for next item");
        return null;
      }

      // Check if the imagePath has a valid extension
      bool hasValidExtension = ['.png', '.jpg', '.jpeg', '.webp', '.gif']
          .any((ext) => imagePath.toLowerCase().endsWith(ext));
      
      if (!hasValidExtension) {
        print("WARNING: Image path doesn't have valid image extension: $imagePath");
        return null;
      }
      
      print("Preparing next image path: $imagePath");
      return imagePath;
    } catch (e) {
      print("ERROR: Failed to validate next image path: $e");
      return null;
    }
  }

  // Method called AFTER an interaction (like Pinata) to display the next item
  Future<void> showPreparedImage() async {
    if (gameItems.isEmpty) {
      print("WARN: showPreparedImage called with empty gameItems.");
      return;
    }

    print("--- showPreparedImage START ---");

    // Save the current word before advancing the index
    final String previousWord = currentIndex < gameItems.length ? gameItems[currentIndex].word.toLowerCase() : "";
    
    // 1. Advance Index
    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = random.nextInt(3) + 1; // Assuming 3 variations max
    print("  Index advanced to: $currentIndex");

    // 2. Get the NEW current item *after* index update
    if (currentIndex >= gameItems.length) {
      print("ERROR: Current index $currentIndex out of bounds after update!");
      // Reset index or handle error appropriately
      currentIndex = 0;
      if (gameItems.isEmpty) return; // Double check after potential reset
    }
    final GameItem newItem = gameItems[currentIndex];
    print("  New current item: ${newItem.word} (Index: $currentIndex)");

    // 3. Reset Played Status for the PREVIOUS word
    if (previousWord.isNotEmpty) {
      _playedQuestions.remove(previousWord);
      print("  Reset played status for previous word: $previousWord");
    }

    // 4. Generate new options for the *new* item
    final List<String> newOptions = newItem.generateOptions(allLetters);
    print("  Generated ${newOptions.length} options for ${newItem.word}: $newOptions");

    // --- ATOMIC STATE UPDATE ---
    // Update all relevant state variables *before* notifying listeners

    // a. Set the generated options
    currentOptions = newOptions;

    // b. Explicitly set counts based on FIXED_COUNT (which should be 3)
    const int FIXED_COUNT = 3;
    visibleLetterCount = FIXED_COUNT;
    coloredLetterCount = FIXED_COUNT; // Assuming all start colored

    // c. Set other relevant states
    lettersAreDraggable = true; // Letters should be draggable for the new item
    isImageVisible = true;      // Show the image for the new item
    isQuestionPlaying = false;  // Reset question playing flag

    print("  State prepared: visible=$visibleLetterCount, colored=$coloredLetterCount, draggable=$lettersAreDraggable, imageVisible=$isImageVisible");
    print("  Final currentOptions state: $currentOptions");

    // 5. Notify UI to Rebuild *ONCE* after all state is set
    notifyListeners();
    print("--- showPreparedImage COMPLETE - Listeners Notified ---");
  }


  @override
  void dispose() {
    // Clean up if necessary, e.g., audio callbacks
    // audioService.onCongratsStart = null; // Already removed this specific one
    super.dispose();
  }

  // Add this method to reset played questions and other state when resetting the game
  // Ensure this is called from appropriate places (e.g., a reset button)
  void resetGame() {
    print("Resetting game state...");
    _playedQuestions.clear();
    currentIndex = 0;
    _gameStarted = false;
    isImageVisible = false;
    visibleLetterCount = 0;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    if(gameItems.isNotEmpty) {
        gameItems.shuffle(random); // Reshuffle for a new round
        currentOptions = gameItems[currentIndex].generateOptions(allLetters);
        visibleLetterCount = currentOptions.length; // Prepare count for start
    } else {
        currentOptions = [];
        visibleLetterCount = 0;
    }
    _isLoading = false; // Assuming items are still loaded
    notifyListeners();
  }

  // Removed unused _prepareOptionsForItem and playQuestionAndRevealLetters methods
  // Removed hideLetters method
}

// Extension method seems unused in the provided flow, can be kept or removed
// extension GameItemListExtension on List<GameItem> {
//   Future<GameItem?> getNextItem() async {
//     if (isEmpty) return null;
//     // Example implementation, adjust if needed
//     int currentIndex = 0; // Needs access to actual current index
//     int nextIndex = (currentIndex + 1) % length;
//     return this[nextIndex];
//   }
// }

// Ensure GameItem class and its generateOptions method are defined correctly elsewhere.
// Ensure AssetLoader class is defined correctly elsewhere.