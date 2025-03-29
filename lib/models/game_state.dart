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
        directory: 'images',
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
      'assets/images/apple.jpeg',
      'assets/images/ball.jpeg',
      'assets/images/cat.jpeg',
    ];
    
    gameItems = defaults.map((path) => GameItem.fromImagePath(path)).toList();
    notifyListeners();
  }
  
  Future<void> playQuestionAndRevealLetters() async {
    if (gameItems.isEmpty) return;
    
    isQuestionPlaying = true;
    notifyListeners();
    
    try {
      String wordName = currentItem!.word;
      await audioService.playQuestion(wordName, questionVariation);
      await audioService.waitForQuestionCompletion();
      
      await revealLettersSequentially();
    } catch (e) {
      await revealLettersSequentially();
    }
  }
  
  Future<void> revealLettersSequentially() async {
    isQuestionPlaying = false;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    for (int i = 0; i < currentOptions.length; i++) {
      coloredLetterCount = i + 1;
      notifyListeners();
      
      await audioService.playLetter(currentOptions[i]);
      await audioService.waitForLetterCompletion();

      if (i < currentOptions.length - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
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
    questionVariation = 1;

    final int nextIndex = (currentIndex + 1) % gameItems.length;
    final String? nextImagePath = gameItems.length > 1 ? gameItems[nextIndex].imagePath : null;

    currentOptions = gameItems[currentIndex].generateOptions(allLetters);

    visibleLetterCount = currentOptions.length;
    coloredLetterCount = 0;
    lettersAreDraggable = false;
    isQuestionPlaying = false;
    isImageVisible = true;

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300)); 

    playQuestionAndRevealLetters();

    return nextImagePath; 
  }
  
  // New method to start the game only when user is ready
  Future<void> startGame() async {
    if (_gameStarted) return; // Don't start twice
    
    _gameStarted = true;
    isImageVisible = true; // Now show the image
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 300));
    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}