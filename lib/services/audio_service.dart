import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

class AudioService {
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _questionPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();
  final AudioPlayer _congratsPlayer = AudioPlayer();
  final AudioPlayer _genericPlayer = AudioPlayer();
  
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
  
  Future<void> playWord(String word) async {
    try {
      String audioPath = 'assets/audio/words/${word.toLowerCase()}.mp3';
      await _wordPlayer.setAsset(audioPath);
      await _wordPlayer.play();
    } catch (e) {
      print('Error playing word audio: $e');
    }
  }
  
  Future<void> playQuestion(String word, int questionVariation) async {
    try {
      // Try to play specific question for this word
      String questionAudioPath = 'assets/audio/questions/${word.toLowerCase()}_question_$questionVariation.mp3';
      
      try {
        await rootBundle.load(questionAudioPath);
        await _questionPlayer.setAsset(questionAudioPath);
        await _questionPlayer.play();
        
        // Return the player for the caller to wait for completion if needed
        return;
      } catch (e) {
        // If specific question not found, play general question
        String generalQuestionPath = 'assets/audio/questions/_question_$questionVariation.mp3';
        await _questionPlayer.setAsset(generalQuestionPath);
        await _questionPlayer.play();
      }
    } catch (e) {
      print('Error playing question audio: $e');
    }
  }
  
  Future<void> playLetter(String letter) async {
    try {
      String audioPath = 'assets/audio/letters/${letter.toLowerCase()}.mp3';
      await rootBundle.load(audioPath); // Check if audio exists
      await _letterPlayer.setAsset(audioPath);
      await _letterPlayer.play();
    } catch (e) {
      print('Error playing letter audio: $e');
    }
  }

  Future<void> playAudio(String audioPath) async {
    try {
      await rootBundle.load(audioPath); // Check if audio exists
      await _genericPlayer.setAsset(audioPath);
      await _genericPlayer.play();
      await _waitForCompletion(_genericPlayer);
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> playCongratulations() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for congratulatory audio files
      final congratsFiles = manifestMap.keys
          .where((key) => key.startsWith('assets/audio/congrats/') && 
                         key.endsWith('.mp3'))
          .toList();

      if (congratsFiles.isNotEmpty) {
        final random = Random();
        final randomFile = congratsFiles[random.nextInt(congratsFiles.length)];
        await _congratsPlayer.setAsset(randomFile);
        await _congratsPlayer.play();
        await _waitForCompletion(_congratsPlayer);
        
        // After congrats finishes, play correct.mp3
        await _congratsPlayer.setAsset('assets/audio/other/correct.mp3');
        await _congratsPlayer.play();
        await _waitForCompletion(_congratsPlayer);
      }
    } catch (e) {
      print('Error playing congratulatory audio: $e');
    }
  }
  
  Future<void> _waitForCompletion(AudioPlayer player) async {
    try {
      await player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
    } catch (e) {
      print('Error waiting for audio completion: $e');
    }
  }

  Future<void> waitForQuestionCompletion() async {
    await _waitForCompletion(_questionPlayer);
  }
}