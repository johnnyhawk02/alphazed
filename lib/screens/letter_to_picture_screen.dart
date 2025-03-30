import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import 'pinata_screen.dart'; // Import the new PinataScreen
import 'base_game_screen.dart';

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');
  
  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {
  @override
  bool get fullScreenMode => false; // Enable full screen mode to remove padding and AppBar

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
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
    
    // Only play question audio if we're not coming back from a pinata screen
    // This needs to happen directly after the image becomes visible
    if (gameState.currentItem != null && !gameState.hasQuestionBeenPlayed(gameState.currentItem!.word)) {
      print('🎯 Attempting to play question for: ${gameState.currentItem!.word}');
      
      // Mark it as played IMMEDIATELY before attempting to play it
      gameState.markQuestionAsPlayed(gameState.currentItem!.word);
      
      // Use Future.microtask to avoid blocking the UI
      Future.microtask(() async {
        try {
          // Play the question audio with the current variation
          await audioService.playQuestion(gameState.currentItem!.word, gameState.questionVariation);
        } catch (e) {
          print('💥 Error in question audio playback: $e');
        }
      });
    } else {
      print('⏭️ Skipping question for: ${gameState.currentItem!.word} - already played');
    }
    
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
    // Remove question audio playback from here - it's now handled in buildImageDropTarget
    
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
                          // Instead of showing pinata overlay, navigate to the PinataScreen
                          // Add this flag to prevent the question from playing when returning from pinata
                          gameState.markQuestionAsPlayed(gameState.currentItem!.word);
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PinataScreen(
                                onComplete: () {
                                  // Return to the main game screen
                                  Navigator.of(context).pop();
                                  
                                  // Now proceed to next image but don't play question audio
                                  // We'll explicitly mark the next question as played to prevent it
                                  final gameState = Provider.of<GameState>(context, listen: false);
                                  
                                  // This ensures the question won't be played for the next image
                                  if (gameState.gameItems.isNotEmpty) {
                                    int nextIndex = (gameState.currentIndex + 1) % gameState.gameItems.length;
                                    if (nextIndex < gameState.gameItems.length) {
                                      gameState.markQuestionAsPlayed(gameState.gameItems[nextIndex].word);
                                    }
                                  }
                                  
                                  gameState.showPreparedImage();
                                },
                              ),
                            ),
                          );
                          
                          // Just prepare the next image without advancing to it
                          if (mounted) {
                            final String? nextImagePath = await gameState.prepareNextImage();
                            
                            // Precache the image for faster loading later
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