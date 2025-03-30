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
  
  // Set to track words for which questions have already been played
  final Set<String> _wordsWithQuestionsPlayed = {};
  
  // Public method to check if a word has had its question played
  bool hasQuestionBeenPlayed(String word) {
    return _wordsWithQuestionsPlayed.contains(word);
  }
  
  // Public method to mark a word as having had its question played
  void markQuestionAsPlayed(String word) {
    _wordsWithQuestionsPlayed.add(word);
  }
  
  bool isQuestionPlaying = false;
  int visibleLetterCount = 0;
  int coloredLetterCount = 0;
  bool lettersAreDraggable = false;
  bool isImageVisible = false;
  List<String> currentOptions = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  // Add a new property to control whether game has fully started
  bool _gameStarted = false;
  bool get gameStarted => _gameStarted;
  
  GameItem? get currentItem => gameItems.isEmpty ? null : gameItems[currentIndex];
  
  GameState({required this.audioService}) {
    audioService.onCongratsStart = hideLetters;
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
        _loadDefaultItems();
        if (gameItems.isEmpty) {
           print("Error: No game items loaded, including defaults.");
        }
      }
      
      gameItems = imageFiles.map((path) => GameItem.fromImagePath(path)).toList();
      gameItems.shuffle(random);
      
      if (gameItems.isNotEmpty) {
        currentOptions = gameItems[currentIndex].generateOptions(allLetters);
        visibleLetterCount = currentOptions.length;
        coloredLetterCount = 0;
        lettersAreDraggable = false;
        isQuestionPlaying = false;
        isImageVisible = false; // Keep image hidden until game starts
      } else {
        currentOptions = [];
        visibleLetterCount = 0;
        coloredLetterCount = 0;
        lettersAreDraggable = false;
        isQuestionPlaying = false;
        isImageVisible = false;
      }
      
      // Remove automatic playback - we'll start this only when the user taps to start
      // await Future.delayed(const Duration(milliseconds: 300)); 
      // await playQuestionAndRevealLetters();
    } catch (e) {
      print("Error loading game items: $e");
      _loadDefaultItems();
      if (gameItems.isNotEmpty) {
         currentOptions = gameItems[currentIndex].generateOptions(allLetters);
      } else {
        currentOptions = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _loadDefaultItems() {
    final defaults = [
      'assets/images/words/apple.jpeg',
      'assets/images/words/ball.jpeg',
      'assets/images/words/cat.jpeg',
    ];
    
    gameItems = defaults.map((path) => GameItem.fromImagePath(path)).toList();
    notifyListeners();
  }
  
  Future<void> playQuestionAndRevealLetters() async {
    if (gameItems.isEmpty) return;
    
    // Set everything visible and interactive immediately
    isQuestionPlaying = false;
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = currentOptions.length;
    lettersAreDraggable = true;
    notifyListeners();
  }
  
  void hideLetters() {
    visibleLetterCount = 0;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    notifyListeners();
  }
  
  Future<String?> prepareNextImage() async {
    if (gameItems.isEmpty) return null;
    
    // Get the next index but don't immediately move to it
    final int nextIndex = (currentIndex + 1) % gameItems.length;
    return gameItems[nextIndex].imagePath;
  }
  
  // This method is called when we're actually ready to show the next image
  Future<void> showPreparedImage() async {
    if (gameItems.isEmpty) return;
    
    // Now actually advance to the next image
    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = 1;
    
    currentOptions = gameItems[currentIndex].generateOptions(allLetters);
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = currentOptions.length; // Show all letters colored
    lettersAreDraggable = true; // Make them immediately draggable
    isQuestionPlaying = true; // Set to true since we'll play the question
    isImageVisible = true;
    notifyListeners();
    
    // Play the question for the new turn
    if (currentItem != null && !hasQuestionBeenPlayed(currentItem!.word)) {
      // Mark this word as having had its question played
      markQuestionAsPlayed(currentItem!.word);
      
      // Play the question for the current word
      await audioService.playQuestion(currentItem!.word, questionVariation);
      
      // After question finishes, update the state
      isQuestionPlaying = false;
      notifyListeners();
    }
  }
  
  // New method to start the game only when user is ready
  Future<void> startGame() async {
    if (_gameStarted) return; // Don't start twice
    
    _gameStarted = true;
    isImageVisible = true; // Now show the image
    
    // Show all letter buttons simultaneously
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = currentOptions.length;
    lettersAreDraggable = true;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}