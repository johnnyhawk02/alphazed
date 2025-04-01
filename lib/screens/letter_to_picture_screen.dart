import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart'; // Uses the GameState WITHOUT GamePhase
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'pinata_screen.dart';
import 'fireworks_screen.dart';
import 'ripple_screen.dart'; // Assuming ripple_screen.dart exists
import 'base_game_screen.dart';

// --- LetterPictureMatch Screen Widget ---
class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');

  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

// --- _LetterPictureMatchState ---
class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {

  @override
  bool get fullScreenMode => false;

  @override
  void initState() {
    super.initState();
  }

  // --- Build Portrait Layout ---
  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // --- Image Area ---
        Container(
          key: targetContainerKey,
          child: buildImageDropTarget(gameState, audioService),
        ),
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding * 1.5),
        // --- Letter Buttons Area ---
        Expanded(
          flex: GameConfig.letterButtonsFlex,
          child: buildLetterGrid(gameState, audioService),
        ),
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding),
        if (fullScreenMode) SizedBox(height: MediaQuery.of(context).padding.bottom + GameConfig.defaultPadding),
      ],
    );
  }

  // --- Build Image Drop Target ---
  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth;

    // --- Placeholder Logic ---
    // REVERTED: Use isImageVisible and gameStarted flags instead of gamePhase
    if (!gameState.isImageVisible || !gameState.gameStarted || gameState.currentItem == null) {
      print("INFO: Image not visible, game not started, or currentItem is null. Showing placeholder.");
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: const BoxDecoration( color: Colors.transparent, ),
      );
    }

    final currentItem = gameState.currentItem!;

    // --- Play Question Audio ---
    if (!gameState.hasQuestionBeenPlayed(currentItem.word)) {
      print('🎯 Attempting to play question for: ${currentItem.word}');
      gameState.markQuestionAsPlayed(currentItem.word);
      Future.microtask(() async {
        try {
          await audioService.playQuestion(currentItem.word, gameState.questionVariation);
          print('🎧 Question audio playback initiated for ${currentItem.word}');
        } catch (e) { print('💥 Error playing question audio for ${currentItem.word}: $e'); }
      });
    } else {
      print('⏭️ Skipping question for: ${currentItem.word} - already played.');
    }

    // --- Display Actual Image ---
    return Hero(
      tag: 'game_image_${currentItem.imagePath}',
      child: SizedBox(
        width: imageSize,
        height: imageSize,
        child: ImageDropTarget(
          key: ValueKey(currentItem.imagePath),
          item: currentItem,
          onLetterAccepted: (letter) async {
            if (letter.toLowerCase() != currentItem.firstLetter.toLowerCase()) {
              print("❌ Incorrect letter '$letter' dropped (Audio Trigger)");
              audioService.playIncorrect();
            } else {
              print("✅ Correct letter '$letter' dropped (Audio handled by button)");
            }
          },
        ),
      ),
    );
  }

  // --- Build Letter Grid ---
  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    // --- Debug Logging ---
    print('--- Building Letter Grid ---');
    print('Current Item: ${gameState.currentItem?.word ?? "None"}');
    print('Current Options: ${gameState.currentOptions} (Count: ${gameState.currentOptions.length})');
    print('Visible Letter Count: ${gameState.visibleLetterCount}');
    print('Colored Letter Count: ${gameState.coloredLetterCount}');
    print('Letters Draggable: ${gameState.lettersAreDraggable}');
    print('--------------------------');

    // --- Calculate Sizes ---
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;
    final buttonPadding = screenWidth * GameConfig.letterButtonPaddingFactor;

    // --- Get Current Item Safely ---
    final currentItem = gameState.currentItem;

    // --- Handle Empty State ---
    if (currentItem == null) {
      print("WARN: buildLetterGrid called with null item. Rendering empty.");
      return const Center(child: SizedBox.shrink());
    }

    // --- Normalize options to always have exactly 3 letters ---
    // Ensure we have exactly 3 options, even if GameState provides fewer or more
    const int FIXED_COUNT = 3;
    final List<String> normalizedOptions = List<String>.filled(FIXED_COUNT, "?");
    for (int i = 0; i < FIXED_COUNT && i < gameState.currentOptions.length; i++) {
      normalizedOptions[i] = gameState.currentOptions[i];
    }
    print("Normalized options: $normalizedOptions (from original: ${gameState.currentOptions})");

    // --- Prepare Correct Letter Info ---
    final String correctFirstLetterLower = currentItem.firstLetter.toLowerCase();
    final bool areButtonsDraggable = gameState.lettersAreDraggable;

    // --- Build Button Row ---
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: GameConfig.defaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            FIXED_COUNT,
            (index) {
              final String currentLetter = normalizedOptions[index];
              final String currentLetterLower = currentLetter.toLowerCase();
              final bool isThisTheCorrectLetter = currentLetterLower == correctFirstLetterLower;

              print("BUILDING LetterButton: index=$index, letter='$currentLetter'");

              // Add padding around each button
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                // --- Reverted back to LetterButton --- 
                child: LetterButton(
                  // Make key more specific to the current word and letter/index
                  key: ValueKey('letter_${currentItem.word}_${currentLetter}_$index'),
                  letter: currentLetter,
                  isCorrectLetter: isThisTheCorrectLetter,
                  onTap: () => audioService.playLetter(currentLetter),
                  colored: index < gameState.coloredLetterCount, // Keep existing color logic
                  draggable: areButtonsDraggable,
                  onDragSuccess: (wasCorrectDrop) async {
                    if (!mounted) return;

                    if (wasCorrectDrop) {
                      print("✅ Correct letter '$currentLetter' matched! (Screen notified)");
                      await audioService.playCongratulations();
                      // Access GameState using Provider within the async callback if needed
                      final currentGameState = Provider.of<GameState>(context, listen: false);
                      currentGameState.markQuestionAsPlayed(currentItem.word);

                      String? nextImagePath;
                      try {
                        print("🚀 Preparing next image before Celebration...");
                        nextImagePath = await currentGameState.prepareNextImage();
                        if (nextImagePath != null && mounted) {
                          precacheImage(AssetImage(nextImagePath), context).then((_) {
                             print("🖼️ Precached image: $nextImagePath");
                          }).catchError((e, s) {
                             print("⚠️ Failed to precache image: $nextImagePath, Error: $e\n$s");
                          });
                        }
                      } catch (e) {
                        print("💥 Error preparing next image: $e");
                      }

                      if (mounted) {
                        // Pass the GameState obtained from Provider
                        _navigateToNextCelebration(currentGameState, audioService);
                      }
                    } else {
                      print("❌ Incorrect letter '$currentLetter' drop processed. (Screen notified)");
                    }
                  },
                ),
                // --- End of Revert ---
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Helper Method for Sequential Navigation ---
  void _navigateToNextCelebration(GameState gameState, AudioService audioService) {

    // --- Check Developer Setting --- 
    if (!GameConfig.showCelebrationScreens) {
      print("DEV SETTING: Skipping celebration screen.");
      // Directly trigger the logic that happens after celebration
      // Use WidgetsBinding to schedule this after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
            print("🔄 Requesting GameState to show prepared image (celebration skipped)...");
            // Access gameState directly since it's passed into this method
            gameState.showPreparedImage(); 
        }
      });
      return; // Exit the function early
    }

    // --- Original Celebration Logic (only runs if showCelebrationScreens is true) ---
    final List<Widget Function(AudioService, VoidCallback)> celebrationScreenFactories = [
      (audio, onComplete) => PinataScreen(audioService: audio, onComplete: onComplete),
      (audio, onComplete) => FireworksScreen(audioService: audio, onComplete: onComplete),
      (audio, onComplete) => RippleScreen(audioService: audio, onComplete: onComplete),
    ];

    final int screenIndex = gameState.getAndIncrementNextCelebrationIndex(celebrationScreenFactories.length);
    if (screenIndex >= celebrationScreenFactories.length || screenIndex < 0) { /* Handle error */ return; }
    final selectedScreenFactory = celebrationScreenFactories[screenIndex];

    final VoidCallback onCelebrationComplete = () {
      if (mounted) {
        print("🎉 Celebration complete. Popping screen.");
        if(Navigator.canPop(context)) { Navigator.of(context).pop(); }
        else { print("WARN: Cannot pop celebration screen."); }

        // REVERTED: Call original showPreparedImage directly
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
                final postCelebrationGameState = Provider.of<GameState>(context, listen: false);
                print("🔄 Requesting GameState to show prepared image post-celebration...");
                postCelebrationGameState.showPreparedImage(); // Call the existing method
            }
        });
      }
    };

    final celebrationScreen = selectedScreenFactory(audioService, onCelebrationComplete);

    Navigator.of(context).push(
      MaterialPageRoute( builder: (context) => celebrationScreen, ),
    );
  }
} // End of _LetterPictureMatchState