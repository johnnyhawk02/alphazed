import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _questionPlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();
  
  AudioService() {
    // Initialize audio players with default volume
    _wordPlayer.setVolume(1.0);
    _questionPlayer.setVolume(1.0);
    _letterPlayer.setVolume(1.0);
  }
  
  void dispose() {
    _wordPlayer.dispose();
    _questionPlayer.dispose();
    _letterPlayer.dispose();
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
  
  Future<void> waitForQuestionCompletion() async {
    try {
      await _questionPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
    } catch (e) {
      print('Error waiting for question completion: $e');
    }
  }
}