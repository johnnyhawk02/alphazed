import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart'; // Ensure GameConfig is correctly imported
import '../models/game_state.dart';    // Ensure GameState is correctly imported
import '../services/audio_service.dart'; // Ensure AudioService is correctly imported
import '../widgets/image_drop_target.dart'; // Ensure ImageDropTarget is correctly imported
import '../widgets/letter_button.dart';     // Ensure LetterButton is correctly imported
import 'pinata_screen.dart';             // Ensure PinataScreen is correctly imported
import 'base_game_screen.dart';          // Ensure BaseGameScreen is correctly imported

// --- LetterPictureMatch Screen Widget ---
// This screen handles the main game loop of matching letters to pictures.
class LetterPictureMatch extends BaseGameScreen {
  // Constructor passing the title to the base screen.
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');

  // Creates the state object for this screen.
  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

// --- _LetterPictureMatchState ---
// The state class for the LetterPictureMatch screen.
class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {

  // --- Screen Configuration ---
  // Override from BaseGameScreen to control AppBar and padding behavior.
  // Set to `true` for an edge-to-edge layout without an AppBar.
  // Set to `false` to include the AppBar and default padding.
  @override
  bool get fullScreenMode => true; // Example: Using full screen mode

  @override
  void initState() {
    super.initState();
    // Optional: Initial setup or data loading logic can go here.
    // Example: Triggering game load if not handled elsewhere.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<GameState>(context, listen: false).loadGameItems();
    // });
  }

  // --- Build Portrait Layout ---
  // Defines the main layout structure for the screen in portrait mode.
  // This method is required by BaseGameScreenState.
  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    // Use a Column for vertical arrangement of elements.
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // Align content towards the top.
      children: [
        // --- Image Area ---
        // Container holding the image drop target. Size is determined within buildImageDropTarget.
        Container(
          key: targetContainerKey, // Optional key from BaseGameScreenState.
          child: buildImageDropTarget(gameState, audioService),
        ),

        // --- Optional Spacing ---
        // Add vertical space if not in full screen mode (since AppBar takes space).
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding * 1.5),

        // --- Letter Buttons Area ---
        // Use Expanded to allow the button area to fill available vertical space.
        Expanded(
          // Control relative vertical space using flex factor from config.
          flex: GameConfig.letterButtonsFlex,
          child: buildLetterGrid(gameState, audioService),
        ),

        // --- Bottom Padding ---
        // Add padding at the bottom. Especially useful if not in full screen mode
        // to avoid system navigation bars/gestures.
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding),
        // Even in full screen mode, add padding equal to system bottom inset plus default padding.
        if (fullScreenMode) SizedBox(height: MediaQuery.of(context).padding.bottom + GameConfig.defaultPadding),
      ],
    );
  }

  // --- Build Image Drop Target ---
  // Constructs the widget displaying the current image, which also acts as a drop target.
  // Handles triggering the question audio.
  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Determine image size (e.g., full screen width for 1:1 aspect ratio).
    final imageSize = screenWidth;

    // --- Placeholder Logic ---
    // If the image shouldn't be visible yet or the game item isn't loaded, show a placeholder.
    if (!gameState.isImageVisible || gameState.currentItem == null) {
      print("INFO: Image not visible or currentItem is null. Showing placeholder.");
      return Container(
        width: imageSize,
        height: imageSize, // Maintain aspect ratio
        decoration: const BoxDecoration(
          // Use a transparent or subtle background for the placeholder.
          color: Colors.transparent, // Or Colors.grey.shade200
        ),
      );
    }

    // --- Image Visible Logic ---
    // Safely access the current game item.
    final currentItem = gameState.currentItem!;

    // --- Play Question Audio ---
    // Check if the question for this specific word has already been played in this round.
    if (!gameState.hasQuestionBeenPlayed(currentItem.word)) {
      print('🎯 Attempting to play question for: ${currentItem.word}');
      // Mark the question as played *immediately* to prevent duplicates from rapid rebuilds.
      gameState.markQuestionAsPlayed(currentItem.word);

      // Use Future.microtask to play audio without blocking the build method.
      Future.microtask(() async {
        try {
          await audioService.playQuestion(currentItem.word, gameState.questionVariation);
          print('🎧 Question audio playback initiated for ${currentItem.word}');
        } catch (e) {
          // Log errors during audio playback.
          print('💥 Error playing question audio for ${currentItem.word}: $e');
        }
      });
    } else {
      // Skip playing the question if it was already played.
      print('⏭️ Skipping question for: ${currentItem.word} - already played.');
    }

    // --- Display Actual Image ---
    // Use a Hero widget for smooth transitions (if applicable, e.g., from a selection screen).
    return Hero(
      tag: 'game_image_${currentItem.imagePath}', // Unique tag for the Hero animation.
      // Use SizedBox to explicitly constrain the size of the ImageDropTarget.
      child: SizedBox(
        width: imageSize,
        height: imageSize,
        // The ImageDropTarget widget displays the image and handles letter drops.
        child: ImageDropTarget(
          // Use ValueKey to ensure the widget updates correctly when the item changes.
          key: ValueKey(currentItem.imagePath),
          item: currentItem, // The current game item data.
          // Callback when a letter is dropped and accepted onto the target.
          onLetterAccepted: (letter) async {
            // Check if the dropped letter is incorrect.
            if (letter.toLowerCase() != currentItem.firstLetter.toLowerCase()) {
              print("❌ Incorrect letter '$letter' dropped on ${currentItem.word} (Audio Trigger)");
              // Play the incorrect sound feedback via the AudioService.
              audioService.playIncorrect();
              // Note: Visual feedback (emoji) for incorrect drops is handled by the LetterButton itself.
            } else {
              // Correct letter dropped. Sound feedback is handled by LetterButton's onDragSuccess.
              print("✅ Correct letter '$letter' dropped (Audio handled by button)");
            }
          },
        ),
      ),
    );
  }

  // --- Build Letter Grid ---
  // Constructs the row/grid of letter buttons at the bottom of the screen.
  // This method is required by BaseGameScreenState.
  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    // --- Debug Logging ---
    // Log current state values helpful for debugging button visibility/state issues.
    print('--- Building Letter Grid ---');
    print('Current Item: ${gameState.currentItem?.word ?? "None"}');
    print('Current Options: ${gameState.currentOptions} (Count: ${gameState.currentOptions.length})');
    print('Visible Letter Count: ${gameState.visibleLetterCount}'); // Crucial for button visibility!
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
    // If there's no current item or no options, render an empty container.
    if (currentItem == null || gameState.currentOptions.isEmpty) {
       print("WARN: buildLetterGrid called with null item or empty options. Rendering empty.");
       return const Center(child: SizedBox.shrink()); // Or a loading indicator/message
    }

    // --- Prepare Correct Letter Info ---
    // Get the correct first letter for comparison.
    final String correctFirstLetterLower = currentItem.firstLetter.toLowerCase();

    // --- Build Button Row ---
    // Use Center to horizontally center the Row of buttons.
    return Center(
      // Use SingleChildScrollView if buttons might overflow the screen width.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: GameConfig.defaultPadding), // Optional vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center buttons within the Row.
          // Generate a list of widgets (LetterButtons or SizedBox placeholders).
          children: List.generate(
            gameState.currentOptions.length, // Number of buttons/slots matches options.
            (index) {
              // Get the letter for the current button.
              final String currentLetter = gameState.currentOptions[index];
              final String currentLetterLower = currentLetter.toLowerCase();
              // Determine if this specific button represents the correct letter.
              final bool isThisTheCorrectLetter = currentLetterLower == correctFirstLetterLower;

              // Add padding around each button/placeholder for spacing.
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                // Use AnimatedSwitcher for smooth transitions between LetterButton and SizedBox.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300), // Animation duration.
                  // Define the transition animation (e.g., scale and fade).
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  // Conditionally render a LetterButton or an empty SizedBox.
                  // The condition `index < gameState.visibleLetterCount` controls actual button visibility.
                  child: index < gameState.visibleLetterCount
                      // --- Render LetterButton ---
                      ? LetterButton(
                          // Use a unique ValueKey for efficient updates and animations.
                          key: ValueKey('letter_${currentLetter}_$index'),
                          letter: currentLetter,
                          // Pass whether this button holds the correct letter.
                          isCorrectLetter: isThisTheCorrectLetter,
                          // Action to perform when the button is tapped.
                          onTap: () => audioService.playLetter(currentLetter),
                          // Control the visual state (colored/active letter text).
                          colored: index < gameState.coloredLetterCount,
                          // Control whether the button can be dragged.
                          draggable: gameState.lettersAreDraggable,

                          // --- Drag Success Callback ---
                          // This is called by the LetterButton after a drag ends.
                          // The `wasCorrectDrop` boolean indicates if it was accepted AND correct.
                          onDragSuccess: (wasCorrectDrop) async {
                            // Ensure the widget is still mounted before proceeding.
                            if (!mounted) return;

                            // --- Handle CORRECT Drop ---
                            if (wasCorrectDrop) {
                              print("✅ Correct letter '$currentLetter' matched! (Screen notified)");

                              // Play the congratulatory sound effect and wait for it to finish
                              await audioService.playCongratulations();

                              // Mark the current question as played (safeguard).
                              gameState.markQuestionAsPlayed(currentItem.word);

                              // --- Prepare Next Image Asynchronously ---
                              // Start preparing the next image data before navigating away.
                              String? nextImagePath;
                              try {
                                print("🚀 Preparing next image before Pinata...");
                                nextImagePath = await gameState.prepareNextImage();
                                // If preparation was successful and widget is still mounted, precache.
                                if (nextImagePath != null && mounted) {
                                  // Precache without awaiting to avoid blocking the UI thread.
                                  precacheImage(AssetImage(nextImagePath), context).then((_) {
                                     print("🖼️ Precached image: $nextImagePath");
                                  }).catchError((e, s) {
                                     // Log errors during precaching.
                                     print("⚠️ Failed to precache image: $nextImagePath, Error: $e\n$s");
                                  });
                                }
                              } catch (e) {
                                print("💥 Error preparing next image: $e");
                              }

                              // --- Navigate to Pinata Screen ---
                              // Push the PinataScreen onto the navigation stack.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PinataScreen(
                                    audioService: audioService, // Pass audio service.
                                    // --- Pinata Completion Callback ---
                                    // This runs when the PinataScreen signals completion.
                                    onComplete: () {
                                      // Check mounted status again inside the async callback.
                                      if (!mounted) return;

                                      print("🎉 Pinata complete. Popping screen.");
                                      // Return from the PinataScreen.
                                      Navigator.of(context).pop();

                                      // Access GameState safely (listen: false) to trigger actions.
                                      final postPinataGameState = Provider.of<GameState>(context, listen: false);

                                      // --- Prevent Next Question Audio ---
                                      // Mark the *next* item's question as played *before* showing it,
                                      // to prevent it auto-playing immediately after the pinata sequence.
                                      int potentialNextIndex = (postPinataGameState.currentIndex + 1) % postPinataGameState.gameItems.length;
                                      if (postPinataGameState.gameItems.isNotEmpty && potentialNextIndex < postPinataGameState.gameItems.length) {
                                         final nextItemWord = postPinataGameState.gameItems[potentialNextIndex].word;
                                         print("🤫 Marking question for upcoming item [$nextItemWord] as played post-pinata.");
                                         postPinataGameState.markQuestionAsPlayed(nextItemWord);
                                      } else {
                                         print("⚠️ Could not determine next item to mark question played post-pinata.");
                                      }

                                      // --- Show Next Item ---
                                      // Tell GameState to update its state to show the next (already prepared) item.
                                      print("🔄 Requesting GameState to show prepared image...");
                                      postPinataGameState.showPreparedImage();
                                    },
                                  ),
                                ),
                              );
                            }
                            // --- Handle INCORRECT Drop ---
                            else {
                              // The drop was accepted but was the wrong letter.
                              // Sound feedback was handled by ImageDropTarget.
                              // Visual feedback (emoji) was handled by LetterButton.
                              print("❌ Incorrect letter '$currentLetter' drop processed. (Screen notified)");
                              // No further action needed here unless specified.
                            }
                          },
                        )
                      // --- Render Placeholder ---
                      // If index >= gameState.visibleLetterCount, render an empty SizedBox
                      // to maintain layout spacing while the button is "invisible".
                      : SizedBox(
                          // Provide a key for stable animations.
                          key: ValueKey('empty_$index'),
                          width: buttonSize,
                          height: buttonSize,
                          // Optional: Add a visual placeholder style if desired.
                          // child: Container(decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                        ),
                ),
              );
            },
          ).toList(), // Convert the generated iterable to a List for the Row children.
        ),
      ),
    );
  }
}