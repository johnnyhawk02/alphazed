import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_item.dart';
import '../services/audio_service.dart';
import '../services/asset_loader.dart';
import '../config/game_config.dart';
import 'package:flutter/widgets.dart';

class GameState extends ChangeNotifier {
  final AudioService audioService;
  List<GameItem> gameItems = [];
  final List<String> allLetters = List.generate(26, (index) => String.fromCharCode(97 + index)); // Changed from 65 to 97 for lowercase
  int currentIndex = 0;
  int questionVariation = 1;
  final Random random = Random();
  
  bool isQuestionPlaying = false;
  int visibleLetterCount = 0;
  int coloredLetterCount = 0;
  bool lettersAreDraggable = false;
  bool isImageVisible = false;
  List<String> currentOptions = [];
  
  GameItem? get currentItem => gameItems.isEmpty ? null : gameItems[currentIndex];
  
  GameState({required this.audioService}) {
    audioService.onCongratsStart = hideLetters;
  }
  
  Future<void> loadGameItems() async {
    try {
      final imageFiles = await AssetLoader.getAssets(
        directory: 'images',
        extensions: ['.jpeg', '.jpg', '.png']
      );
      
      if (imageFiles.isEmpty) {
        _loadDefaultItems();
        return;
      }
      
      gameItems = imageFiles.map((path) => GameItem.fromImagePath(path)).toList();
      gameItems.shuffle(random);
      
      // First, prepare letter options
      currentOptions = gameItems[currentIndex].generateOptions(allLetters);
      
      // Reset state: Show letters (gray), show image frame, not draggable
      visibleLetterCount = currentOptions.length;
      coloredLetterCount = 0;
      lettersAreDraggable = false;
      isQuestionPlaying = false;
      isImageVisible = true; // Show image frame immediately
      
      // Update UI once to show gray letters and image frame
      notifyListeners();
      
      // Short delay for UI to build before starting audio sequence
      await Future.delayed(const Duration(milliseconds: 300)); 
      
      // Now start the audio sequence
      await playQuestionAndRevealLetters();
    } catch (e) {
      _loadDefaultItems();
    }
  }
  
  void _loadDefaultItems() {
    final defaults = [
      'assets/images/apple.jpeg',
      'assets/images/ball.jpeg',
      'assets/images/cat.jpeg',
    ];
    
    gameItems = defaults.map((path) => GameItem.fromImagePath(path)).toList();
    notifyListeners();
  }
  
  Future<void> playQuestionAndRevealLetters() async {
    if (gameItems.isEmpty) return;
    
    // Don't reset the letter visibility state here - they're already visible
    // Just signal that the question is playing
    isQuestionPlaying = true;
    notifyListeners();
    
    try {
      // Play the question audio
      String wordName = currentItem!.word;
      await audioService.playQuestion(wordName, questionVariation);
      await audioService.waitForQuestionCompletion();
      
      // After question completes, start revealing letters with color
      await revealLettersSequentially();
    } catch (e) {
      // Fallback in case of error
      await revealLettersSequentially();
    }
  }
  
  Future<void> revealLettersSequentially() async {
    // Ensure letters are visible but not colored/draggable initially
    isQuestionPlaying = false;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    notifyListeners(); // Update UI to show gray letters

    // Allow a brief moment for the initial state to render
    await Future.delayed(const Duration(milliseconds: 50));

    for (int i = 0; i < currentOptions.length; i++) {
      // Color the current letter
      coloredLetterCount = i + 1;
      notifyListeners();
      
      // Play the letter sound
      await audioService.playLetter(currentOptions[i]);
      await audioService.waitForLetterCompletion();

      // Wait 1 second before revealing the next letter (if any)
      if (i < currentOptions.length - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    // After all letters are revealed and sounds played, make them draggable
    // Add a small delay before making them draggable for better UX
    await Future.delayed(const Duration(milliseconds: 300)); 
    lettersAreDraggable = true;
    notifyListeners();
  }
  
  void hideLetters() {
    visibleLetterCount = 0;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    notifyListeners();
  }
  
  Future<String?> nextImage() async {
    if (gameItems.isEmpty) return null;

    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = 1; // Always use question variation 1

    // Calculate the index of the *next* image to precache
    final int nextIndex = (currentIndex + 1) % gameItems.length;
    final String? nextImagePath = gameItems.length > 1 ? gameItems[nextIndex].imagePath : null;

    // Prepare letter options for the *current* next image
    currentOptions = gameItems[currentIndex].generateOptions(allLetters);

    // Reset state: Show letters (gray), show new image frame, not draggable
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    isQuestionPlaying = false;
    isImageVisible = true; // Show image frame immediately

    // Update UI once to show gray letters and new image frame
    notifyListeners();

    // Short delay for UI to build before starting audio sequence
    await Future.delayed(const Duration(milliseconds: 300)); 

    // Start the audio sequence for the new item
    playQuestionAndRevealLetters(); // Keep this non-awaited for precaching

    // Return the path for the *next* image so the UI layer can precache it
    return nextImagePath; 
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}