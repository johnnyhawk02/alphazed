import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Keep Completer for image preloading test
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../widgets/color_picker_dialog.dart';
import 'pinata_screen.dart';
import 'dot_swish_screen.dart';
import 'ripple_screen.dart';
import 'monster_mash_screen.dart'; // <-- Import the new screen
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
    // Any specific init logic for this screen
  }

  // Override buildGameAppBar to show current word instead of static title
  @override
  PreferredSizeWidget buildGameAppBar() {
    // Get the current word from gameState using Provider.of instead of Consumer
    final GameState gameState = Provider.of<GameState>(context, listen: true);
    final String displayTitle = gameState.currentItem?.word.toLowerCase() ?? "picture matching";
    final double screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      elevation: 1,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 70,
      automaticallyImplyLeading: false, // Disable back button
      title: Container(
        // Consider adjusting width or using FittedBox if titles are long
        width: screenWidth / 2, // Adjusted width slightly
        child: Text(
          displayTitle,
          style: GameConfig.titleTextStyle.copyWith(
            fontSize: 35.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // Handle long words
          maxLines: 1,
        ),
      ),
      actions: [
        // Add the color options menu
        IconButton(
          icon: const Icon(Icons.color_lens),
          tooltip: 'Change Background Color', // Added tooltip
          onPressed: () {
            _showColorPickerDialog();
          },
        ),
      ],
    );
  }

  // Add the missing _showColorPickerDialog method (assuming it's the same as in base class, but added here for clarity)
  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => const ColorPickerDialog(),
    );
  }

  // --- Build Portrait Layout ---
  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Check if device is likely an iPad (using aspect ratio and screen size)
    bool isIpad = mediaQuery.size.shortestSide >= 600 &&
                (screenWidth / screenHeight).abs() < 1.6;

    // Use device-specific flex values from GameConfig
    final int imageAreaFlexValue = isIpad
        ? GameConfig.ipadImageAreaFlex
        : GameConfig.iphoneImageAreaFlex;

    final int buttonAreaFlexValue = isIpad
        ? GameConfig.ipadLetterButtonsFlex
        : GameConfig.iphoneLetterButtonsFlex;

    return Column(
      // Consider adding mainAxisAlignment if needed, e.g., MainAxisAlignment.spaceAround
      children: [
        // --- Image Area ---
        Expanded(
          flex: imageAreaFlexValue,
          child: Container(
            key: targetContainerKey, // Ensure base class key is used
            alignment: Alignment.center, // Center the drop target within Expanded
            child: buildImageDropTarget(gameState, audioService),
          ),
        ),
        // Add some spacing unless in full screen mode
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding * 1.5),
        // --- Letter Buttons Area ---
        Expanded(
          flex: buttonAreaFlexValue,
          child: buildLetterGrid(gameState, audioService),
        ),
        // Spacing at the bottom
        if (!fullScreenMode) SizedBox(height: GameConfig.defaultPadding),
        // Add bottom padding if in full screen to avoid system navigation
        if (fullScreenMode) SizedBox(height: MediaQuery.of(context).padding.bottom + GameConfig.defaultPadding),
      ],
    );
  }

  // --- Build Image Drop Target ---
  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    // --- Placeholder Logic ---
    if (!gameState.isImageVisible || !gameState.gameStarted || gameState.currentItem == null) {
      print("INFO: Image not visible, game not started, or currentItem is null. Showing placeholder.");
      // Return an empty container or a placeholder widget
      return Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: const Center(child: SizedBox.shrink()), // Or CircularProgressIndicator()
      );
    }

    final currentItem = gameState.currentItem!;

    // --- Play Question Audio ---
    // Schedule audio play after the build phase completes to avoid issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !gameState.hasQuestionBeenPlayed(currentItem.word)) {
            print('🎯 Attempting to play question for: ${currentItem.word}');
            gameState.markQuestionAsPlayed(currentItem.word);
            audioService.playQuestion(currentItem.word, gameState.questionVariation)
                .then((_) => print('🎧 Question audio playback initiated for ${currentItem.word}'))
                .catchError((e) => print('💥 Error playing question audio for ${currentItem.word}: $e'));
        } else if (mounted) {
            print('⏭️ Skipping question for: ${currentItem.word} - already played or widget not mounted.');
        }
    });


    // --- Display Actual Image ---
    // Use Hero for potential transitions (ensure tag uniqueness)
    return Hero(
      tag: 'game_image_${currentItem.imagePath}', // Unique tag per image
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0, // Keep image aspect ratio (usually square)
          child: ImageDropTarget(
            // Use ValueKey for efficient updates when item changes
            key: ValueKey('drop_target_${currentItem.imagePath}'),
            item: currentItem,
            onLetterAccepted: (letter) async {
              // This callback is triggered when a letter is successfully dropped
              if (letter.toLowerCase() != currentItem.firstLetter.toLowerCase()) {
                print("❌ Incorrect letter '$letter' dropped (Audio Trigger)");
                // Incorrect feedback sound is handled by the DropTarget via ThemeProvider flash
                // but we can play an additional sound if needed
                 audioService.playIncorrect();
              } else {
                print("✅ Correct letter '$letter' dropped (Audio handled by button/drag success)");
                // Correct feedback is handled by the LetterButton's onDragSuccess
              }
            },
          ),
        ),
      ),
    );
  }

  // --- Build Letter Grid ---
  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    // --- Debug Logging ---
    // print('--- Building Letter Grid ---');
    // print('Current Item: ${gameState.currentItem?.word ?? "None"}');
    // print('Current Options: ${gameState.currentOptions}');
    // print('Letters Draggable: ${gameState.lettersAreDraggable}');
    // print('--------------------------');

    // --- Calculate Sizes ---
    final screenWidth = MediaQuery.of(context).size.width;
    // Button size and padding factors from GameConfig
    final buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;
    final buttonPadding = screenWidth * GameConfig.letterButtonPaddingFactor;

    // --- Get Current Item Safely ---
    final currentItem = gameState.currentItem;

    // --- Handle Empty State ---
    if (currentItem == null || gameState.currentOptions.isEmpty) {
      print("WARN: buildLetterGrid called with null item or no options. Rendering empty.");
      return const Center(child: SizedBox.shrink()); // Or a loading indicator
    }

    // --- Normalize options to always have exactly 3 letters ---
    const int FIXED_COUNT = 3;
    final List<String> normalizedOptions = List<String>.filled(FIXED_COUNT, "?"); // Fill with placeholder
    for (int i = 0; i < FIXED_COUNT && i < gameState.currentOptions.length; i++) {
      normalizedOptions[i] = gameState.currentOptions[i];
    }
    // print("Normalized options: $normalizedOptions (from original: ${gameState.currentOptions})");

    // --- Prepare Correct Letter Info ---
    final String correctFirstLetterLower = currentItem.firstLetter.toLowerCase();
    final bool areButtonsDraggable = gameState.lettersAreDraggable;

    // --- Build Button Row ---
    return Center(
      child: SingleChildScrollView( // Allow horizontal scrolling if buttons overflow
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: GameConfig.defaultPadding), // Add vertical padding if needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center buttons horizontally
          children: List.generate(
            FIXED_COUNT,
            (index) {
              final String currentLetter = normalizedOptions[index];
              final String currentLetterLower = currentLetter.toLowerCase();
              final bool isThisTheCorrectLetter = currentLetterLower == correctFirstLetterLower;

              // print("BUILDING LetterButton: index=$index, letter='$currentLetter'");

              // Add padding around each button
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                child: LetterButton(
                  // Ensure key uniqueness: depends on item, letter, and index
                  key: ValueKey('letter_${currentItem.word}_${currentLetter}_$index'),
                  letter: currentLetter,
                  isCorrectLetter: isThisTheCorrectLetter,
                  onTap: () => audioService.playLetter(currentLetter),
                  // Visibility/Coloring based on GameState (adjust logic if needed)
                  colored: index < gameState.coloredLetterCount, // Or always true if they should always be visible
                  draggable: areButtonsDraggable,
                  onDragSuccess: (wasCorrectDrop) async {
                    if (!mounted) return;

                    if (wasCorrectDrop) {
                      print("✅ Correct letter '$currentLetter' matched! (Screen notified)");

                      // Play congrats sound and wait for it (optional)
                      await audioService.playCongratulations();

                      // Access GameState safely within the async callback
                      final currentGameState = Provider.of<GameState>(context, listen: false);

                       // Mark question as played *after* congrats? Or immediately? Choose one.
                       // currentGameState.markQuestionAsPlayed(currentItem.word); // Moved potentially

                      String? nextImagePath;
                      try {
                        print("🚀 Preparing next image before Celebration...");
                        nextImagePath = await currentGameState.prepareNextImage();
                        if (nextImagePath != null && mounted) {
                          // Precache the next image in the background
                           print("🖼️ Preloading image: $nextImagePath");
                           precacheImage(AssetImage(nextImagePath), context).then((_) {
                             print("✅ Precached image SUCCESS: $nextImagePath");
                           }).catchError((e, s) {
                             print("⚠️ Failed to precache image: $nextImagePath, Error: $e\n$s");
                             // Don't block navigation if precaching fails
                           });

                           // --- Simpler Validation (optional - remove if precache is enough) ---
                           // You could add a simple check here if the path looks valid,
                           // but relying on precache error handling might be sufficient.
                           // bool isValidPath = nextImagePath.toLowerCase().endsWith('.png') || ... ;
                           // if (!isValidPath) { print("⚠️ Invalid image path format: $nextImagePath"); }
                           // --- End Simpler Validation ---

                        } else if (nextImagePath == null) {
                           print("🤔 No next image path returned by GameState.");
                        }
                      } catch (e) {
                        print("💥 Error preparing or precaching next image: $e");
                        // Handle error gracefully, maybe proceed without preloading
                      }

                      // Ensure we're still mounted before navigating
                      if (mounted) {
                        // Pass the GameState obtained from Provider
                        _navigateToNextCelebration(currentGameState, audioService);
                      }
                    } else {
                      print("❌ Incorrect letter '$currentLetter' drop processed. (Screen notified)");
                      // Incorrect sound/feedback is handled by DropTarget/LetterButton itself
                    }
                  },
                ),
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
            // Ensure showPreparedImage is robust against null items if game ends etc.
            gameState.showPreparedImage();
        }
      });
      return; // Exit the function early
    }

    // --- Original Celebration Logic (only runs if showCelebrationScreens is true) ---
    final List<Widget Function(AudioService, VoidCallback)> celebrationScreenFactories = [
      (audio, onComplete) => PinataScreen(audioService: audio, onComplete: onComplete),
      (audio, onComplete) => DotSwishScreen(audioService: audio, onComplete: onComplete),
      (audio, onComplete) => RippleScreen(audioService: audio, onComplete: onComplete),
      (audio, onComplete) => MonsterMashScreen(audioService: audio, onComplete: onComplete), // <-- Added new screen
    ];

    // Get the index for the next screen in the cycle
    final int screenIndex = gameState.getAndIncrementNextCelebrationIndex(celebrationScreenFactories.length);

    // Basic safety check for the index
    if (screenIndex < 0 || screenIndex >= celebrationScreenFactories.length) {
       print("Error: Invalid celebration screen index: $screenIndex. Resetting index.");
       // Optionally reset the index in GameState here if needed, or just default to 0
       // gameState.resetCelebrationIndex(); // Assuming such a method exists
       // Fallback to the first screen or handle error differently
       final selectedScreenFactory = celebrationScreenFactories[0]; // Fallback
    }

    final selectedScreenFactory = celebrationScreenFactories[screenIndex];

    // Define what happens when the celebration screen finishes
    final VoidCallback onCelebrationComplete = () {
      if (mounted) {
        print("🎉 Celebration complete. Popping screen.");
        // Safely pop the route if possible
        if(Navigator.canPop(context)) {
            Navigator.of(context).pop();
        } else {
            print("WARN: Cannot pop celebration screen. Already popped?");
        }

        // Schedule the GameState update for the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
                // Get potentially updated GameState instance
                final postCelebrationGameState = Provider.of<GameState>(context, listen: false);
                print("🔄 Requesting GameState to show prepared image post-celebration...");
                postCelebrationGameState.showPreparedImage(); // Call the state update method
            }
        });
      } else {
         print("WARN: onCelebrationComplete called but widget is not mounted.");
      }
    };

    // Create the celebration screen widget instance
    final celebrationScreen = selectedScreenFactory(audioService, onCelebrationComplete);

    // Navigate to the celebration screen
    Navigator.of(context).push(
      // Use MaterialPageRoute or a custom route if needed
      MaterialPageRoute( builder: (context) => celebrationScreen ),
    );
  }

} // End of _LetterPictureMatchState