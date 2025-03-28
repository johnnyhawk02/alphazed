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
    
    // Add a small delay and force another update to ensure letters are visible
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    
    // First reveal each letter one by one, then play the audio
    for (int i = 0; i < currentOptions.length; i++) {
      // First color this letter (reveal it visually)
      coloredLetterCount = i + 1;
      notifyListeners();
      
      // Small delay to allow the user to see the newly revealed letter
      // Increasing the delay for the first letter to ensure it appears
      await Future.delayed(Duration(milliseconds: i == 0 ? 500 : 200));
      
      // Force MULTIPLE updates to ensure the letter text is visible
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 50));
      notifyListeners();
      
      // Then play the letter sound
      await audioService.playLetter(currentOptions[i]);
      
      // Wait for the letter sound to complete
      await audioService.waitForLetterCompletion();
      
      // Wait before next letter
      if (i < currentOptions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    // After all letters are colored and sounds played, make them draggable
    await Future.delayed(const Duration(milliseconds: 700));
    lettersAreDraggable = true;
    notifyListeners();
    
    // Final update to ensure all letters are properly visible and draggable
    await Future.delayed(const Duration(milliseconds: 100));
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
    questionVariation = 1; // Always use question variation 1
    
    // Prepare letter options for the next image
    currentOptions = gameItems[currentIndex].generateOptions(allLetters);
    
    // Reset state for the new item: letters visible but gray, image hidden
    visibleLetterCount = currentOptions.length;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    isQuestionPlaying = false;
    isImageVisible = false;  // Hide the image initially
    
    // Notify UI once to show the initial state (gray letters, no image)
    notifyListeners();
    
    // Wait a consolidated delay for UI to settle and user to see letters
    // Adjust duration as needed, combining previous delays
    await Future.delayed(const Duration(milliseconds: 700)); 

    // Now, check if the widget is still mounted before proceeding
    // (Although GameState is usually long-lived, this is good practice)
    // We assume GameState itself won't be disposed mid-operation, 
    // but the UI listening might change.
    // No direct 'mounted' check here, rely on listeners handling disposal.

    // Show the image
    isImageVisible = true;
    notifyListeners();
    
    // Wait briefly for image to appear visually before starting audio
    await Future.delayed(const Duration(milliseconds: 300)); 
    
    // Start the audio sequence
    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}