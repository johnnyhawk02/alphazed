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
  
  Future<void> loadGameItems() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final imageFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/images/') && 
                         (key.endsWith('.jpeg') || 
                          key.endsWith('.jpg') || 
                          key.endsWith('.png')))
          .toList();
      
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
      String letter = currentOptions[i];
      
      visibleLetterCount = i + 1;
      notifyListeners();
      
      try {
        await audioService.playLetter(letter);
      } catch (e) {
        print('Error playing letter audio: $e');
      }
    }
  }
  
  Future<void> _playCongratulatoryAudio() async {
    try {
      // Get the manifest file which contains all the assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for congratulatory audio files
      final congratsFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/audio/congrats/') && 
                         key.endsWith('.mp3'))
          .toList();

      if (congratsFiles.isNotEmpty) {
        final randomFile = congratsFiles[random.nextInt(congratsFiles.length)];
        await audioService.playAudio(randomFile);
      }
      
      // Play the 'correct.mp3' audio
      await audioService.playAudio('assets/audio/other/correct.mp3');
    } catch (e) {
      print('Error playing congratulatory audio: $e');
    }
  }

  Future<void> nextImage() async {
    // Play congratulatory audio before proceeding to the next turn
    await _playCongratulatoryAudio();

    currentIndex = (currentIndex + 1) % gameItems.length;
    questionVariation = random.nextInt(GameConfig.maxQuestionVariations) + 1;
    visibleLetterCount = 0;
    notifyListeners();

    await playQuestionAndRevealLetters();
  }
  
  @override
  void dispose() {
    audioService.dispose();
    super.dispose();
  }
}