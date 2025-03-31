import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'pinata_screen.dart'; // Import the PinataScreen
import 'base_game_screen.dart';

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');

  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {
  // --- Configuration ---
  // Set to true for edge-to-edge image and no AppBar.
  // Set to false to keep AppBar and default padding from BaseGameScreen.
  @override
  bool get fullScreenMode => true; // Example: Enable full screen

  @override
  void initState() {
    super.initState();
    // Optionally trigger game load here if not handled elsewhere
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<GameState>(context, listen: false).loadGameItems();
    // });
  }

  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    // Use Column for vertical arrangement
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
      children: [
        // --- Image Area ---
        Container(
          key: targetContainerKey, // Key from BaseGameScreenState if needed
          // Size is determined by buildImageDropTarget
          child: buildImageDropTarget(gameState, audioService),
        ),
        // Add spacing between image and letters if needed
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding * 1.5),

        // --- Letter Buttons Area ---
        // Use Expanded to take remaining space, or adjust based on layout needs
        Expanded(
          flex: GameConfig.letterButtonsFlex, // Use config for flex factor
          child: buildLetterGrid(gameState, audioService),
        ),
        // Add bottom padding, especially useful if not in full screen mode
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding),
         // Add some padding at the very bottom in full screen mode too for gestures
        if (fullScreenMode) SizedBox(height: MediaQuery.of(context).padding.bottom + GameConfig.defaultPadding)
      ],
    );
  }

  // Builds the image area, handling visibility and audio triggers
  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    final screenWidth = MediaQuery.of(context).size.width;
    // For full screen, use screen width. Adjust if constraints change.
    final imageSize = screenWidth;

    // Show placeholder if image isn't ready or visible
    if (!gameState.isImageVisible || gameState.currentItem == null) {
      print("INFO: Image not visible or currentItem is null. Showing placeholder.");
      return Container(
        width: imageSize,
        height: imageSize, // Maintain aspect ratio
        decoration: const BoxDecoration(
          // Consistent background, no border radius to match image display
          color: Colors.transparent, // Or Colors.grey.shade200 for visibility
        ),
      );
    }

    // --- Image is Visible ---
    final currentItem = gameState.currentItem!; // Safe access due to check above

    // Trigger question audio ONLY if it hasn't been played for this word yet
    if (!gameState.hasQuestionBeenPlayed(currentItem.word)) {
      print('🎯 Attempting to play question for: ${currentItem.word}');
      // Mark immediately to prevent replays from rapid rebuilds
      gameState.markQuestionAsPlayed(currentItem.word);

      // Play async without blocking build
      Future.microtask(() async {
        try {
          await audioService.playQuestion(currentItem.word, gameState.questionVariation);
          print('🎧 Question audio playback initiated for ${currentItem.word}');
        } catch (e) {
          print('💥 Error playing question audio for ${currentItem.word}: $e');
        }
      });
    } else {
      print('⏭️ Skipping question for: ${currentItem.word} - already played.');
    }

    // Display the actual image using Hero animation and DropTarget
    return Hero(
      tag: 'game_image_${currentItem.imagePath}', // Unique tag for animation
      child: SizedBox( // Use SizedBox to constrain the DropTarget size
        width: imageSize,
        height: imageSize,
        child: ImageDropTarget(
          key: ValueKey(currentItem.imagePath), // Ensure widget updates when item changes
          item: currentItem,
          onLetterAccepted: (letter) async {
            // Feedback for incorrect drop - correct feedback is handled by LetterButton drag success
            if (letter.toLowerCase() != currentItem.firstLetter.toLowerCase()) {
              print("❌ Incorrect letter '$letter' dropped on ${currentItem.word}");
              audioService.playIncorrect();
            } else {
              // Correct letter dropped - sound is played by LetterButton's success callback
              print("✅ Correct letter '$letter' dropped (sound handled by button)");
            }
          },
        ),
      ),
    );
  }

  // Builds the grid/row of letter buttons
  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    // --- Logging for Debugging ---
    print('--- Building Letter Grid ---');
    print('Current Item: ${gameState.currentItem?.word ?? "None"}');
    print('Current Options: ${gameState.currentOptions} (Count: ${gameState.currentOptions.length})');
    print('Visible Letter Count: ${gameState.visibleLetterCount}'); // <<< WATCH THIS VALUE
    print('Colored Letter Count: ${gameState.coloredLetterCount}');
    print('Letters Draggable: ${gameState.lettersAreDraggable}');
    print('--------------------------');

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;
    final buttonPadding = screenWidth * GameConfig.letterButtonPaddingFactor;

    final currentItem = gameState.currentItem; // Get current item safely

    // Handle case where options might be empty or item is null temporarily
    if (currentItem == null || gameState.currentOptions.isEmpty) {
       print("WARN: buildLetterGrid called with null item or empty options. Rendering empty.");
       return const Center(child: SizedBox.shrink()); // Render nothing if no options
    }


    // Use Center and Row for horizontally centered buttons
    return Center(
      child: SingleChildScrollView( // Allows scrolling if buttons overflow horizontally
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            gameState.currentOptions.length, // Generate based on available options
            (index) {
              // Use Padding for spacing between buttons
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                // AnimatedSwitcher handles the appearance/disappearance of buttons vs placeholders
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    // Optional: Fade and scale transition
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  // Conditionally render LetterButton or SizedBox based on visibleLetterCount
                  child: index < gameState.visibleLetterCount
                      ? LetterButton(
                          // Unique key based on letter and index is crucial for AnimatedSwitcher
                          key: ValueKey('letter_${gameState.currentOptions[index]}_$index'),
                          letter: gameState.currentOptions[index],
                          onTap: () => audioService.playLetter(gameState.currentOptions[index]),
                          // 'visible' prop removed from LetterButton as AnimatedSwitcher handles presence
                          colored: index < gameState.coloredLetterCount, // Control color state
                          draggable: gameState.lettersAreDraggable,     // Control drag state
                          onDragSuccess: (success) async {
                            if (!mounted) return; // Ensure widget is still in the tree

                            final bool isCorrect = success &&
                                gameState.currentOptions[index].toLowerCase() ==
                                    currentItem.firstLetter.toLowerCase();

                            if (isCorrect) {
                              print("✅ Correct letter '${gameState.currentOptions[index]}' matched!");
                              // --- Play Correct Sound using EFFECT player ---
                              audioService.playCongratulations(); // Use the correct service method

                              // Mark current question played as a safeguard before navigation
                              // (though it should be marked already when image appeared)
                              gameState.markQuestionAsPlayed(currentItem.word);

                              // --- Prepare Next Image BEFORE Navigating ---
                              String? nextImagePath;
                              try {
                                print("🚀 Preparing next image before Pinata...");
                                nextImagePath = await gameState.prepareNextImage();
                                if (nextImagePath != null && mounted) {
                                  // Precache without awaiting here to avoid blocking UI
                                  precacheImage(AssetImage(nextImagePath), context).then((_) {
                                     print("🖼️ Precached image: $nextImagePath");
                                  }).catchError((e, s) {
                                     print("⚠️ Failed to precache image: $nextImagePath, Error: $e\n$s");
                                  });
                                }
                              } catch (e) {
                                print("💥 Error preparing next image: $e");
                              }

                              // --- Navigate to Pinata Screen ---
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PinataScreen(
                                    audioService: audioService,
                                    onComplete: () {
                                      // --- Pinata Completion Callback ---
                                      if (!mounted) return; // Check mounted status again

                                      print("🎉 Pinata complete. Popping screen.");
                                      Navigator.of(context).pop(); // Return from Pinata

                                      // Access GameState safely after returning
                                      final postPinataGameState = Provider.of<GameState>(context, listen: false);

                                      // Mark the *next* item's question as played immediately BEFORE showing it.
                                      // This prevents the question audio from auto-playing after Pinata.
                                      int potentialNextIndex = (postPinataGameState.currentIndex + 1) % postPinataGameState.gameItems.length;
                                      if (postPinataGameState.gameItems.isNotEmpty && potentialNextIndex < postPinataGameState.gameItems.length) {
                                         final nextItemWord = postPinataGameState.gameItems[potentialNextIndex].word;
                                         print("🤫 Marking question for upcoming item [$nextItemWord] as played post-pinata.");
                                         postPinataGameState.markQuestionAsPlayed(nextItemWord);
                                      } else {
                                         print("⚠️ Could not determine next item to mark question played post-pinata.");
                                      }

                                      // Trigger GameState to show the prepared next item
                                      print("🔄 Requesting GameState to show prepared image...");
                                      postPinataGameState.showPreparedImage();
                                    },
                                  ),
                                ),
                              );
                            }
                            // Incorrect drop feedback is handled by ImageDropTarget's onLetterAccepted
                          },
                        )
                      : SizedBox(
                          // Provide a key for the placeholder too for stable transitions
                          key: ValueKey('empty_$index'),
                          width: buttonSize,
                          height: buttonSize,
                          // Optional: Add a subtle placeholder visual if desired
                          // child: Container(
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey.shade300,
                          //     shape: BoxShape.circle,
                          //   ),
                          // ),
                        ),
                ),
              );
            },
          ).toList(), // Explicitly convert to list
        ),
      ),
    );
  }
}