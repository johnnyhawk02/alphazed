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
    // Keep initial debug logs
    print('--- Building Letter Grid ---');
    print('Current Item: ${gameState.currentItem?.word ?? "None"}');
    // REMOVED: Game Phase log
    print('Current Options: ${gameState.currentOptions} (Count: ${gameState.currentOptions.length})');
    print('Visible Letter Count: ${gameState.visibleLetterCount}');
    print('Colored Letter Count: ${gameState.coloredLetterCount}'); // Keep if used below
    print('Letters Draggable: ${gameState.lettersAreDraggable}');
    print('--------------------------');

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;
    final buttonPadding = screenWidth * GameConfig.letterButtonPaddingFactor;

    final currentItem = gameState.currentItem;

    if (currentItem == null || gameState.currentOptions.isEmpty) {
       print("WARN: buildLetterGrid called with null item or empty options. Rendering empty.");
       return const Center(child: SizedBox.shrink());
    }

    final String correctFirstLetterLower = currentItem.firstLetter.toLowerCase();
    // REVERTED: Determine draggability directly from GameState flag
    final bool areButtonsDraggable = gameState.lettersAreDraggable;
    print('Using Draggable State from GameState: $areButtonsDraggable');

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: GameConfig.defaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            gameState.currentOptions.length,
            (index) {
              final String currentLetter = gameState.currentOptions[index];
              final String currentLetterLower = currentLetter.toLowerCase();
              final bool isThisTheCorrectLetter = currentLetterLower == correctFirstLetterLower;

              // Calculate visibility condition using visibleLetterCount
              final bool shouldBeVisible = index < gameState.visibleLetterCount;

              // Keep this log
              print("BUILDING SLOT: index=$index, letter='$currentLetter', visibleLetterCount=${gameState.visibleLetterCount}, shouldBeVisible=$shouldBeVisible");

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                     return ScaleTransition( scale: animation, child: FadeTransition(opacity: animation, child: child) );
                  },
                  child: shouldBeVisible
                      ? LetterButton(
                          key: ValueKey('letter_${currentLetter}_$index'),
                          letter: currentLetter,
                          isCorrectLetter: isThisTheCorrectLetter,
                          onTap: () => audioService.playLetter(currentLetter),
                          // REVERTED: Use coloredLetterCount if your GameState still has it
                          colored: index < gameState.coloredLetterCount,
                          // Use calculated draggability
                          draggable: areButtonsDraggable,
                          // --- Drag Success Callback ---
                          onDragSuccess: (wasCorrectDrop) async {
                            if (!mounted) return;

                            if (wasCorrectDrop) {
                              print("✅ Correct letter '$currentLetter' matched! (Screen notified)");
                              await audioService.playCongratulations();

                              // REVERTED: Removed call to gameState.handleCorrectAnswer()
                              // Original logic likely involved direct state changes or just navigation prep

                              // Mark question as played (might be redundant if done elsewhere, but safe)
                                Provider.of<GameState>(context, listen: false).markQuestionAsPlayed(currentItem.word);

                              // --- Prepare Next Image Asynchronously (Optional but good) ---
                              String? nextImagePath;
                              try {
                                  final currentGameState = Provider.of<GameState>(context, listen: false);
                                  print("🚀 Preparing next image before Celebration...");
                                  nextImagePath = await currentGameState.prepareNextImage();
                                  if (nextImagePath != null && mounted) {
                                    // Precache the next image in the background
                                    precacheImage(AssetImage(nextImagePath), context).then((_) {
                                      print("🖼️ Precached image: $nextImagePath");
                                    }).catchError((e, s) {
                                      print("⚠️ Failed to precache image: $nextImagePath, Error: $e\n$s");
                                    });
                                  }
                              } catch (e) {
                                  print("💥 Error preparing next image: $e");
                              }


                              // --- Navigate to Celebration ---
                              if (mounted) {
                                // Pass the current gameState from provider
                                _navigateToNextCelebration(Provider.of<GameState>(context, listen: false), audioService);
                              }
                            } else {
                              print("❌ Incorrect letter '$currentLetter' drop processed. (Screen notified)");
                            }
                          },
                        )
                      : SizedBox(
                          key: ValueKey('empty_$index'),
                          width: buttonSize,
                          height: buttonSize,
                        ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // --- Helper Method for Sequential Navigation ---
  void _navigateToNextCelebration(GameState gameState, AudioService audioService) {
    // REVERTED: Removed check for GamePhase.BetweenRounds

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