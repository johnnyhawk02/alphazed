import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'asset_loader.dart';

typedef VoidCallback = void Function();

class AudioService {
  // Make player nullable and create it lazily
  AudioPlayer? _player;
  
  // Callback for when congratulations audio starts
  VoidCallback? onCongratsStart;
  
  // Track if we're in the process of creating a player
  bool _isCreatingPlayer = false;
  
  // Get or create the audio player
  Future<AudioPlayer?> _getPlayer() async {
    // If we already have a valid player, return it
    if (_player != null) {
      return _player;
    }
    
    // Prevent multiple simultaneous initializations
    if (_isCreatingPlayer) {
      // Wait a bit and try again
      await Future.delayed(Duration(milliseconds: 100));
      return _player;
    }
    
    _isCreatingPlayer = true;
    
    try {
      // Create a new player with a unique ID
      final player = AudioPlayer();
      await player.setVolume(1.0);
      _player = player;
      return player;
    } catch (e) {
      print('Error creating audio player: $e');
      return null;
    } finally {
      _isCreatingPlayer = false;
    }
  }
  
  void dispose() {
    _player?.dispose();
    _player = null;
  }

  /// Simple method to play any audio file
  Future<void> playAudio(String audioPath) async {
    try {
      final player = await _getPlayer();
      if (player == null) {
        print('Could not get audio player');
        return;
      }
      
      // Stop any currently playing audio
      await player.stop();
      
      // Set up and play the new audio
      await player.setAsset(audioPath);
      await player.play();
    } catch (e) {
      print('Error playing audio $audioPath: $e');
      
      // If we got a platform exception, try to reset the player
      if (e is PlatformException) {
        print('Platform exception in audio - resetting player');
        await _resetPlayer();
      }
    }
  }
  
  /// Reset the player if we encounter platform exceptions
  Future<void> _resetPlayer() async {
    try {
      // Dispose of the current player
      await _player?.dispose();
    } catch (e) {
      // Ignore errors during disposal
    } finally {
      // Clear the reference
      _player = null;
    }
  }
  
  /// Plays the question audio for a word
  Future<void> playQuestion(String word, int variation) async {
    // Always try variation 1 first, regardless of the requested variation
    // since many words only have the first variation available
    final String audioPath = 'assets/audio/questions/${word}_question_1.mp3';
    await playAudio(audioPath);
  }
  
  /// Plays a word pronunciation
  Future<void> playWord(String word) async {
    await playAudio('assets/audio/words/${word.toLowerCase()}.mp3');
  }
  
  /// Plays a letter sound
  Future<void> playLetter(String letter) async {
    await playAudio('assets/audio/letters/${letter.toLowerCase()}_.mp3');
  }
  
  /// Plays congratulations audio
  Future<void> playCongratulations() async {
    onCongratsStart?.call();
    await playAudio('assets/audio/other/correct.mp3');
  }
  
  /// Plays incorrect sound
  Future<void> playIncorrect() async {
    await playAudio('assets/audio/other/wrong.mp3');
  }
}