import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'base_game_screen.dart';
import 'dart:math' as math;

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');
  
  @override
  bool get fullScreenMode => true; // Enable full screen mode to remove padding and AppBar
  
  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Stack(
      children: [
        // Main game content (Column)
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              key: targetContainerKey,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                // Removed border radius to allow image to go edge-to-edge
                boxShadow: [],
              ),
              child: buildImageDropTarget(gameState, audioService),
            ),
            SizedBox(height: GameConfig.defaultPadding * 1.5),
            Expanded(
              flex: GameConfig.letterButtonsFlex,
              child: buildLetterGrid(gameState, audioService),
            ),
            SizedBox(height: GameConfig.defaultPadding),
          ],
        ),
      ],
    );
  }

  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    // If there's no image to show yet, return an empty container with the same size
    if (!gameState.isImageVisible) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width, // 1:1 ratio using screen width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36.0),
          color: Colors.transparent,
        ),
      );
    }
    
    // If the image should be visible, show it immediately without fade-in
    return Hero(
      tag: 'game_image_${gameState.currentItem!.imagePath}',
      child: Container(
        width: MediaQuery.of(context).size.width, // Full screen width
        height: MediaQuery.of(context).size.width, // 1:1 ratio using screen width
        child: ImageDropTarget(
          key: ValueKey(gameState.currentItem!.imagePath),
          item: gameState.currentItem!,
          onLetterAccepted: (letter) async {
            if (letter.toLowerCase() != gameState.currentItem!.firstLetter.toLowerCase()) {
              audioService.playIncorrect();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width, // Use full width for a single line
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the buttons horizontally
          children: List.generate(
            gameState.currentOptions.length, // Use actual number of options instead of hardcoded 3
            (index) {
              if (index < gameState.currentOptions.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    // Use constant from GameConfig for padding factor
                    horizontal: MediaQuery.of(context).size.width * GameConfig.letterButtonPaddingFactor,
                  ),
                  child: index < gameState.visibleLetterCount 
                    ? LetterButton(
                      key: ValueKey('letter_${gameState.currentOptions[index]}_$index'),
                      letter: gameState.currentOptions[index],
                      onTap: () => audioService.playLetter(gameState.currentOptions[index]),
                      visible: true, // Always visible if we're rendering it
                      colored: index < gameState.coloredLetterCount,
                      draggable: gameState.lettersAreDraggable,
                      onDragSuccess: (success) async {
                        if (success && gameState.currentOptions[index].toLowerCase() == gameState.currentItem!.firstLetter.toLowerCase()) {
                          // Play success sounds
                          await audioService.playAudio('assets/audio/other/bell.mp3');
                          await audioService.playCongratulations();
                          
                          // Immediately proceed with the game flow
                          if (mounted) {
                            // Call nextImage and get the path for the *next* image
                            final String? nextImagePath = await gameState.nextImage();

                            // Precache the next image if a path was returned
                            if (nextImagePath != null && context.mounted) {
                              try {
                                await precacheImage(AssetImage(nextImagePath), context);
                              } catch (e) {
                                print("Failed to precache image: $nextImagePath, Error: $e");
                              }
                            }
                          }
                        }
                      },
                    )
                    : SizedBox(
                        // Use the size factor for placeholder as well
                        width: MediaQuery.of(context).size.width * GameConfig.letterButtonSizeFactor, 
                        height: MediaQuery.of(context).size.width * GameConfig.letterButtonSizeFactor,
                      ), // Empty space with same size as button
                );
              } else {
                return const SizedBox(); // Placeholder for missing buttons
              }
            },
          ),
        ),
      ),
    );
  }
}