import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/game_item.dart';
import '../services/audio_service.dart';
import '../config/game_config.dart';

class GameState extends ChangeNotifier {
  final AudioService audioService;
  List<GameItem> gameItems = [];
  final List<String> allLetters = List.generate(26, (index) => String.fromCharCode(65 + index));
  int currentIndex = 0;
  int questionVariation = 1;
  final Random random = Random();
  
  bool isQuestionPlaying = false;
  int visibleLetterCount = 0;
  List<String> currentOptions = [];
  
  GameItem? get currentItem => gameItems.isEmpty ? null : gameItems[currentIndex];
  
  GameState({required this.audioService});
  
  // Shared utility method for asset loading with filtering
  Future<List<String>> _getAssetsWithFilters(String directory, List<String> extensions) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      return manifestMap.keys
          .where((key) => key.startsWith('assets/$directory/') && 
                         extensions.any((ext) => key.endsWith(ext)))
          .toList();
    } catch (e) {
      print('Error loading filtered assets from $directory: $e');
      return [];
    }
  }
  
  Future<void> loadGameItems() async {
    try {
      final imageFiles = await _getAssetsWithFilters('images', ['.jpeg', '.jpg', '.png']);
      
      if (imageFiles.isEmpty) {
        _loadDefaultItems();
        return;
      }
      
      gameItems = imageFiles.map((path) => GameItem.fromImagePath(path)).toList();
      gameItems.shuffle(random);
      notifyListeners();
      
      await playQuestionAndRevealLetters();
    } catch (e) {
      print('Error loading game items: $e');
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
      print('Error playing audio or revealing letters: $e');
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
  
  Future<void> nextImage() async {
    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = random.nextInt(GameConfig.maxQuestionVariations) + 1;
    visibleLetterCount = 0;
    notifyListeners();
    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}