import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../widgets/pinata_widget.dart'; // Import the PinataWidget
import 'base_game_screen.dart';

class LetterPictureMatch extends BaseGameScreen {
  const LetterPictureMatch({super.key}) : super(title: 'Picture Matching');
  
  @override
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {
  bool _showPinata = false;
  
  // Tracks if we're waiting for animations to complete
  bool _isWaitingForAnimations = false;
  
  @override
  bool get fullScreenMode => true; // Enable full screen mode to remove padding and AppBar

  @override
  void initState() {
    super.initState();
  }

  void _handlePinataBroken(bool animationsComplete) {
    print("Pinata broken! Animations complete: $animationsComplete");
    
    // Show celebration message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Fiesta! The pinata broke! 🎉'),
        duration: Duration(seconds: 2),
      ),
    );
    
    if (animationsComplete) {
      // If animations are already complete, move to next turn
      _moveToNextTurn();
    } else {
      // Set flag that we're waiting for animations to complete
      setState(() {
        _isWaitingForAnimations = true;
      });
    }
  }
  
  void _moveToNextTurn() {
    if (mounted) {
      setState(() {
        _showPinata = false;
        _isWaitingForAnimations = false;
      });
      
      // Now proceed to next image
      final gameState = Provider.of<GameState>(context, listen: false);
      gameState.showPreparedImage();
    }
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
        // Show the pinata widget if _showPinata is true
        if (_showPinata)
          Positioned(
            top: 150,
            left: (MediaQuery.of(context).size.width - 540) / 2, // Center horizontally (adjusted for 3x size)
            child: PinataWidget(
              width: 540, // 3x bigger (was 180)
              height: 540, // 3x bigger (was 180)
              intactImagePath: 'assets/images/pinata/pinata_intact.png',
              brokenImagePath: 'assets/images/pinata/pinata_broken.png',
              audioService: audioService, // Pass the audioService
              onBroken: (animationsComplete) {
                if (_isWaitingForAnimations && animationsComplete) {
                  // If we were waiting for animations and they're now complete, proceed
                  _moveToNextTurn();
                } else {
                  // Otherwise handle as usual
                  _handlePinataBroken(animationsComplete);
                }
              },
            ),
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
                          // IMMEDIATELY show the pinata before any audio or animations
                          setState(() {
                            _showPinata = true;
                          });
                          
                          // Only play a simple bell sound - no congratulations or other animations
                          audioService.playAudio('assets/audio/other/bell.mp3');
                          
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