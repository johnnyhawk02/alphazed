import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:collection';
import 'asset_loader.dart';

typedef VoidCallback = void Function();

class AudioService {
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _questionPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();
  final AudioPlayer _congratsPlayer = AudioPlayer();
  final AudioPlayer _genericPlayer = AudioPlayer();
  
  // Cache for preloaded letter sounds
  final Map<String, AudioSource> _letterSoundsCache = HashMap<String, AudioSource>();
  bool _letterSoundsLoaded = false;
  
  VoidCallback? onCongratsStart;
  
  AudioService() {
    // Initialize audio players with default volume
    _wordPlayer.setVolume(1.0);
    _questionPlayer.setVolume(1.0);
    _letterPlayer.setVolume(1.0);
    _congratsPlayer.setVolume(1.0);
    _genericPlayer.setVolume(1.0);
    
    // Preload letter sounds
    preloadLetterSounds();
  }
  
  // Preload all letter sounds into memory
  Future<void> preloadLetterSounds() async {
    if (_letterSoundsLoaded) return;
    
    try {
      // Get all the letter sound files
      final letterFiles = await AssetLoader.getAssets(
        directory: 'audio/letters', 
        extension: '.mp3'
      );
      
      print('Preloading ${letterFiles.length} letter sounds...');
      
      // Create audio sources for each letter and store in cache
      for (final file in letterFiles) {
        final letterKey = _extractLetterFromPath(file);
        if (letterKey.isNotEmpty) {
          _letterSoundsCache[letterKey] = AudioSource.asset(file);
          print('Preloaded sound for letter: $letterKey');
        }
      }
      
      _letterSoundsLoaded = true;
      print('Letter sounds preloading complete. Cached ${_letterSoundsCache.length} sounds.');
    } catch (e) {
      print('Error preloading letter sounds: $e');
    }
  }
  
  // Extract letter key from file path
  String _extractLetterFromPath(String path) {
    // Extract filename from path (e.g., "a_.mp3" from "assets/audio/letters/a_.mp3")
    final filename = path.split('/').last;
    // Remove the underscore and extension to get the letter
    if (filename.length >= 3 && filename.contains('_')) {
      return filename.substring(0, 1).toLowerCase();
    }
    return '';
  }
  
  void dispose() {
    _wordPlayer.dispose();
    _questionPlayer.dispose();
    _letterPlayer.dispose();
    _congratsPlayer.dispose();
    _genericPlayer.dispose();
  }
  
  // Shared method for playing random audio from a directory
  Future<void> _playRandomAudioFromDirectory(String directory, AudioPlayer player) async {
    try {
      final audioFiles = await AssetLoader.getAssets(directory: directory, extension: '.mp3');
      
      if (audioFiles.isNotEmpty) {
        final random = Random();
        final randomFile = audioFiles[random.nextInt(audioFiles.length)];
        await player.setAsset(randomFile);
        await player.play();
        await _waitForCompletion(player);
      }
    } catch (e) {
      // Error handling
    }
  }
  
  // Generic method to safely execute audio operations
  Future<void> _safeAudioOperation(String operationName, Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      // Error handling
    }
  }
  
  Future<void> playWord(String word) async {
    await _safeAudioOperation('playWord', () async {
      String audioPath = 'assets/audio/words/${word.toLowerCase()}.mp3';
      await _wordPlayer.setAsset(audioPath);
      await _wordPlayer.play();
    });
  }
  
  Future<void> playQuestion(String word, int questionVariation) async {
    await _safeAudioOperation('playQuestion', () async {
      // Try to play specific question for this word
      String questionAudioPath = 'assets/audio/questions/${word.toLowerCase()}_question_$questionVariation.mp3';
      
      try {
        await rootBundle.load(questionAudioPath);
        await _questionPlayer.setAsset(questionAudioPath);
        await _questionPlayer.play();
      } catch (e) {
        // If specific question not found, play general question
        String generalQuestionPath = 'assets/audio/questions/_question_$questionVariation.mp3';
        await _questionPlayer.setAsset(generalQuestionPath);
        await _questionPlayer.play();
      }
    });
  }
  
  Future<void> playLetter(String letter) async {
    await _safeAudioOperation('playLetter', () async {
      final letterKey = letter.toLowerCase();
      
      // Use cached audio source if available
      if (_letterSoundsCache.containsKey(letterKey)) {
        print('Playing letter sound for $letter from cache');
        await _letterPlayer.setAudioSource(_letterSoundsCache[letterKey]!);
        await _letterPlayer.play();
      } else {
        // Fall back to loading from asset if not in cache
        String audioPath = 'assets/audio/letters/${letterKey}_.mp3';
        print('Cache miss. Attempting to play letter sound from path: $audioPath');
        
        try {
          await rootBundle.load(audioPath); // Check if audio exists
          await _letterPlayer.setAsset(audioPath);
          await _letterPlayer.play();
        } catch (e) {
          print('Error playing letter sound for $letter: $e');
        }
      }
    });
  }

  Future<void> playAudio(String audioPath) async {
    await _safeAudioOperation('playAudio', () async {
      await rootBundle.load(audioPath); // Check if audio exists
      await _genericPlayer.setAsset(audioPath);
      await _genericPlayer.play();
      await _waitForCompletion(_genericPlayer);
    });
  }

  Future<void> playCongratulations() async {
    await _safeAudioOperation('playCongratulations', () async {
      // Play random congratulatory message
      final audioFiles = await AssetLoader.getAssets(directory: 'audio/congrats', extension: '.mp3');
      
      if (audioFiles.isNotEmpty) {
        final random = Random();
        final randomFile = audioFiles[random.nextInt(audioFiles.length)];
        await _congratsPlayer.setAsset(randomFile);
        
        // Notify that congrats is about to start
        onCongratsStart?.call();
        
        await _congratsPlayer.play();
        await _waitForCompletion(_congratsPlayer);
      }
      
      // After congrats finishes, play correct.mp3
      await _congratsPlayer.setAsset('assets/audio/other/correct.mp3');
      await _congratsPlayer.play();
      await _waitForCompletion(_congratsPlayer);
    });
  }
  
  Future<void> playIncorrect() async {
    await _safeAudioOperation('playIncorrect', () async {
      // First play the wrong sound
      await _genericPlayer.setAsset('assets/audio/other/wrong.mp3');
      await _genericPlayer.play();
      await _waitForCompletion(_genericPlayer);
      
      // Then play a random supportive message
      await _playRandomAudioFromDirectory('audio/support', _genericPlayer);
    });
  }
  
  Future<void> _waitForCompletion(AudioPlayer player) async {
    try {
      // More reliable way to wait for audio completion
      if (player.playing) {
        // First wait for processing to complete
        await player.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed || 
                    state.processingState == ProcessingState.idle
        );
        
        // Small additional delay to ensure proper cleanup
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Error handling
      print('Error waiting for audio completion: $e');
    }
  }
  
  Future<void> waitForQuestionCompletion() async {
    await _waitForCompletion(_questionPlayer);
  }
  
  Future<void> waitForLetterCompletion() async {
    await _waitForCompletion(_letterPlayer);
  }
}