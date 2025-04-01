import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

// Assuming AssetLoader is not strictly needed for the core audio playback logic shown.
// If it is used elsewhere for finding assets, keep the import.
// import 'asset_loader.dart';

// Standard typedef for callbacks
typedef VoidCallback = void Function();

class AudioService {
  // Audio path constants
  static const String _audioBasePath = 'assets/audio';
  static const String _questionsAudioPath = '$_audioBasePath/questions';
  static const String _lettersAudioPath = '$_audioBasePath/letters';
  static const String _wordsAudioPath = '$_audioBasePath/words';
  static const String _congratsAudioPath = '$_audioBasePath/congrats';

  // Player for longer sounds (questions, words) - nullable, created lazily
  AudioPlayer? _mainPlayer;
  bool _isCreatingMainPlayer = false;

  // Separate player for short sound effects (UI feedback) - nullable, created lazily
  AudioPlayer? _effectPlayer;
  bool _isCreatingEffectPlayer = false;

  // Callback hook (optional, keep if used elsewhere)
  VoidCallback? onCongratsStart;

  // Add private field for Random
  final Random _random = Random();

  // Get or create the MAIN audio player instance
  Future<AudioPlayer?> _getMainPlayer() async {
    // Return existing player if available and not disposed
    if (_mainPlayer != null) {
      // Basic check if player might be disposed (not foolproof)
      if (_mainPlayer?.processingState != ProcessingState.idle || _mainPlayer?.playing == true) {
         return _mainPlayer;
      } else {
         // It might be idle after finishing or stopped, check if needs reset
         // For simplicity, let's assume if it exists, it's usable or will be reset on error.
         return _mainPlayer;
      }
    }

    // Prevent race conditions during creation
    if (_isCreatingMainPlayer) {
      // Wait briefly for the ongoing creation to complete
      await Future.delayed(const Duration(milliseconds: 100));
      return _mainPlayer; // Return potentially created player
    }

    _isCreatingMainPlayer = true;
    print("🎧 Creating Main AudioPlayer...");
    try {
      final player = AudioPlayer();
      // Set any default configurations for the main player if needed
      // await player.setVolume(1.0); // Example
      _mainPlayer = player;
      print("🎧 Main AudioPlayer created successfully.");
      return player;
    } catch (e) {
      print('Error creating main audio player: $e');
      _mainPlayer = null; // Ensure it's null on failure
      return null;
    } finally {
      _isCreatingMainPlayer = false;
    }
  }

  // Get or create the EFFECTS audio player instance
  Future<AudioPlayer?> _getEffectPlayer() async {
    if (_effectPlayer != null) {
       // Similar check as above, assume usable if exists
       return _effectPlayer;
    }
    if (_isCreatingEffectPlayer) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _effectPlayer;
    }
    _isCreatingEffectPlayer = true;
     print("💥 Creating Effect AudioPlayer...");
    try {
      final player = AudioPlayer();
      // Effects player might have different defaults (e.g., lower volume)
      await player.setVolume(0.8); // Example: Lower volume for UI effects
      _effectPlayer = player;
       print("💥 Effect AudioPlayer created successfully.");
      return player;
    } catch (e) {
      print('Error creating effect audio player: $e');
       _effectPlayer = null;
      return null;
    } finally {
      _isCreatingEffectPlayer = false;
    }
  }

  // Dispose of both players when the service is no longer needed
  void dispose() {
    print("Disposing AudioService players...");
    _mainPlayer?.dispose();
    _effectPlayer?.dispose();
    _mainPlayer = null;
    _effectPlayer = null;
    print("AudioService players disposed.");
  }

  /// Plays longer audio using the main player. Stops any previous main audio.
  Future<void> playAudio(String audioPath) async {
    print("🎧 Request to play on Main: $audioPath");
    try {
      final player = await _getMainPlayer();
      if (player == null) {
        print('Error: Could not get main audio player for $audioPath');
        return;
      }
      // Stop any currently playing MAIN audio before starting new
      await player.stop();
      // Set the new asset and play
      await player.setAsset(audioPath);
      await player.play();
      print("🎧 Playing on Main: $audioPath -> Started");
    } catch (e) {
      print('Error playing main audio $audioPath: $e');
      // Attempt to reset the player on specific errors
      if (e is PlatformException || e is PlayerException || e is PlayerInterruptedException) {
        print('Exception during main audio playback - resetting main player.');
        await _resetMainPlayer();
      }
    }
  }

  /// Plays short sound effects using the effect player.
  /// Returns a Future that completes when the audio finishes playing.
  Future<void> playShortSoundEffect(String audioPath, {bool stopPreviousEffect = true}) async {
     print("💥 Request to play on Effect: $audioPath (StopPrev: $stopPreviousEffect)");
     try {
      final player = await _getEffectPlayer();
      if (player == null) {
        print('Error: Could not get effect audio player for $audioPath');
        return;
      }

      // Stop the PREVIOUS effect sound if requested
      if (stopPreviousEffect) {
         await player.stop();
      }

      // Load and play the audio
      await player.setAsset(audioPath);
      await player.play();
      print("💥 Playing on Effect: $audioPath -> Started");

      // Wait for the audio to complete
      await player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
      print("💥 Effect completed: $audioPath");

    } catch (e) {
      print('Error playing effect audio $audioPath: $e');
       // Attempt to reset the player on specific errors
      if (e is PlatformException || e is PlayerException || e is PlayerInterruptedException) {
        print('Exception during effect audio playback - resetting effect player.');
        await _resetEffectPlayer();
      }
    }
  }

  /// Reset the MAIN player by disposing and nullifying it.
  Future<void> _resetMainPlayer() async {
    print("Resetting Main Player...");
    // Use a temporary variable to avoid race conditions if called multiple times
    final playerToDispose = _mainPlayer;
    _mainPlayer = null; // Nullify immediately
    try {
        await playerToDispose?.dispose();
        print("Main Player disposed during reset.");
    } catch(e) {
        print("Error disposing main player during reset: $e");
    }
  }

  /// Reset the EFFECT player by disposing and nullifying it.
  Future<void> _resetEffectPlayer() async {
     print("Resetting Effect Player...");
    final playerToDispose = _effectPlayer;
    _effectPlayer = null; // Nullify immediately
    try{
        await playerToDispose?.dispose();
        print("Effect Player disposed during reset.");
    } catch (e) {
        print("Error disposing effect player during reset: $e");
    }
  }

  // --- Methods using the MAIN player (via playAudio) ---

  /// Plays the question audio for a word.
  Future<void> playQuestion(String word, int variation) async {
    final String audioPath = '$_questionsAudioPath/${word}_question_1.mp3';
    await playAudio(audioPath);
  }

  /// Plays a word pronunciation.
  Future<void> playWord(String word) async {
    await playAudio('$_wordsAudioPath/${word.toLowerCase()}.mp3');
  }

  /// Plays a letter sound (treated as a short effect).
  Future<void> playLetter(String letter) async {
    await playShortSoundEffect('$_lettersAudioPath/${letter.toLowerCase()}_.mp3');
  }

  /// Plays congratulations audio (randomized from available messages).
  /// Returns a Future that completes when the audio finishes playing.
  Future<void> playCongratulations() async {
    onCongratsStart?.call();
    final int congratsNumber = _random.nextInt(20) + 1;  // We have 20 congrats messages
    final String congratsPath = '$_congratsAudioPath/congrats_$congratsNumber.mp3';
    final player = await _getEffectPlayer();
    if (player == null) return;

    try {
      await player.setAsset(congratsPath);
      await player.play();
      print("💥 Playing congratulation: $congratsPath");
      
      // Wait for the audio to complete
      await player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
      print("💥 Congratulation completed: $congratsPath");
    } catch (e) {
      print('Error playing congratulations audio: $e');
    }
  }

  /// Plays incorrect sound feedback.
  Future<void> playIncorrect() async {
    await playShortSoundEffect('$_audioBasePath/other/wrong.mp3');
  }

  /// Plays the pinata tap sound.
  Future<void> playPinataTap() async {
    await playShortSoundEffect('$_audioBasePath/other/knock.mp3', stopPreviousEffect: true);
  }

   /// Plays the pinata break sound.
  Future<void> playPinataBreak() async {
    await playShortSoundEffect('$_audioBasePath/other/explosion.mp3', stopPreviousEffect: false);
  }
}