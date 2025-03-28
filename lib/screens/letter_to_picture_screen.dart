import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'base_game_screen.dart';

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');

  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> {
  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Container(
              key: targetContainerKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                boxShadow: [],
              ),
              child: buildImageDropTarget(gameState, audioService),
            ),
          ),
        ),
        SizedBox(height: GameConfig.letterSpacing * 1.5),
        Expanded(
          flex: 2,
          child: buildLetterGrid(gameState, audioService),
        ),
        SizedBox(height: GameConfig.letterSpacing),
      ],
    );
  }

  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    // If there's no image to show yet, return an empty container with the same size
    if (!gameState.isImageVisible) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.6, // Maintain 4:3 aspect ratio
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36.0),
          color: Colors.transparent,
        ),
      );
    }
    
    // If the image should be visible, show it immediately without fade-in
    return Hero(
      tag: 'game_image_${gameState.currentItem!.imagePath}',
      child: ImageDropTarget(
        key: ValueKey(gameState.currentItem!.imagePath),
        item: gameState.currentItem!,
        onLetterAccepted: (letter) async {
          if (letter.toLowerCase() != gameState.currentItem!.firstLetter.toLowerCase()) {
            // Play the incorrect sound (the image flashing is now handled by the ImageDropTarget)
            audioService.playIncorrect();
          }
        },
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
                    horizontal: MediaQuery.of(context).size.width * 0.05, // Make padding proportional to viewport size
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
                          await Future.wait([
                            audioService.playAudio('assets/audio/other/bell.mp3'),
                            audioService.playCongratulations(),
                          ]);
                          
                          if (mounted && context.mounted) {
                            gameState.nextImage();
                          }
                        }
                      },
                    )
                    : SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
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