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
      notifyListeners();
      
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
    
    isQuestionPlaying = true;
    currentOptions = currentItem!.generateOptions(allLetters);
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
    notifyListeners();
    
    for (int i = 0; i < currentOptions.length; i++) {
      await Future.delayed(GameConfig.letterRevealDelay);
      visibleLetterCount = i + 1;
      notifyListeners();
      
      await audioService.playLetter(currentOptions[i]);
    }
  }
  
  void hideLetters() {
    visibleLetterCount = 0;
    notifyListeners();
  }
  
  Future<void> nextImage() async {
    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = random.nextInt(GameConfig.maxQuestionVariations) + 1;
    visibleLetterCount = 0;
    notifyListeners();
    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    audioService.onCongratsStart = null;
    super.dispose();
  }
}