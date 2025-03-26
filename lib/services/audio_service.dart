import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'asset_loader.dart';

typedef VoidCallback = void Function();

class AudioService {
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _questionPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();
  final AudioPlayer _congratsPlayer = AudioPlayer();
  final AudioPlayer _genericPlayer = AudioPlayer();
  
  VoidCallback? onCongratsStart;
  
  AudioService() {
    // Initialize audio players with default volume
    _wordPlayer.setVolume(1.0);
    _questionPlayer.setVolume(1.0);
    _letterPlayer.setVolume(1.0);
    _congratsPlayer.setVolume(1.0);
    _genericPlayer.setVolume(1.0);
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
      // Append underscore to all letter file names
      String audioPath = 'assets/audio/letters/${letter.toLowerCase()}_.mp3';
      print('Attempting to play letter sound: $audioPath'); // Debug log

      try {
        await rootBundle.load(audioPath); // Check if audio exists
        await _letterPlayer.setAsset(audioPath);
        await _letterPlayer.play();
      } catch (e) {
        print('Error playing letter sound for $letter: $e'); // Error log
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
      await player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
    } catch (e) {
      // Error handling
    }
  }

  Future<void> waitForQuestionCompletion() async {
    await _waitForCompletion(_questionPlayer);
  }
}