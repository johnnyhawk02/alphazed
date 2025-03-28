import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_item.dart';
import '../services/audio_service.dart';
import '../services/asset_loader.dart';
import '../config/game_config.dart';

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
      
      // Show letters first (gray, not draggable)
      visibleLetterCount = currentOptions.length;
      coloredLetterCount = 0;
      lettersAreDraggable = false;
      isQuestionPlaying = false;
      
      // Update UI to show just the gray letter buttons (image will be hidden)
      notifyListeners();
      
      // First refresh: Add a second notification to ensure all letters are loaded
      await Future.delayed(GameConfig.letterLoadDelay);
      notifyListeners();
      
      // Wait to ensure UI has updated with letters
      await Future.delayed(GameConfig.uiUpdateDelay);
      
      // Signal to show the image now
      isImageVisible = true;
      notifyListeners();
      
      // Wait to ensure image has appeared
      await Future.delayed(GameConfig.uiUpdateDelay);
      
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
    // We won't reset visibility - keep letters visible
    isQuestionPlaying = false;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    
    // Letters are already visible, no need to set visibleLetterCount again
    // Just update the UI state
    notifyListeners();
    
    // Read and color each letter one by one
    for (int i = 0; i < currentOptions.length; i++) {
      // Play the letter sound
      await audioService.playLetter(currentOptions[i]);
      
      // Wait for the letter sound to complete
      await audioService.waitForLetterCompletion();
      
      // Now color this letter (after sound completes)
      coloredLetterCount = i + 1;
      notifyListeners();
      
      // Wait before next letter
      if (i < currentOptions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // After all letters are colored, make them draggable
    await Future.delayed(const Duration(milliseconds: 700));
    lettersAreDraggable = true;
    notifyListeners();
  }
  
  void hideLetters() {
    visibleLetterCount = 0;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    notifyListeners();
  }
  
  Future<void> nextImage() async {
    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = random.nextInt(GameConfig.maxQuestionVariations) + 1;
    
    // Prepare letter options for the next image
    currentOptions = gameItems[currentIndex].generateOptions(allLetters);
    
    // First show only the letters (gray, not colored, not draggable)
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    isQuestionPlaying = false;
    isImageVisible = false;  // Hide the image initially
    
    // Update UI to show just letters
    notifyListeners();
    
    // Add a second notification to ensure all letters are loaded
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    
    // Wait to ensure UI has updated with letters
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Now show the image
    isImageVisible = true;
    notifyListeners();
    
    // Wait to ensure image has appeared
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Now start the audio sequence
    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}