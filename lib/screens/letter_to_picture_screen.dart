import 'package:flutter/material.dart';
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
  BaseGameScreenState<LetterPictureMatch> createState() => _LetterPictureMatchState();
}

class _LetterPictureMatchState extends BaseGameScreenState<LetterPictureMatch> with TickerProviderStateMixin {
  
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScaleAnimation;
  bool _isCelebrating = false;
  // Store Alignment directly, default to center
  Alignment _celebrationAlignment = Alignment.center; 
  
  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 500), 
      vsync: this,
    );
    
    _celebrationScaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 2.5), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 2.5, end: 0.0), weight: 40),
    ]).animate(_celebrationController);

    // Calculate alignment after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateCelebrationAlignment();
    });
  }

  // New method to calculate alignment
  void _calculateCelebrationAlignment() {
    if (!mounted || targetContainerKey.currentContext == null) return;

    final RenderBox? renderBox = targetContainerKey.currentContext!.findRenderObject() as RenderBox?;
    final Size screenSize = MediaQuery.of(context).size;
    
    if (renderBox != null && screenSize.width > 0 && screenSize.height > 0) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final absoluteOrigin = Offset(position.dx + size.width / 2, position.dy + size.height / 2);

      // Convert absolute origin to fractional offset for Alignment and store it
      // Use setState only if the value actually changes to avoid unnecessary rebuilds
      final newAlignment = Alignment(
        (absoluteOrigin.dx / screenSize.width) * 2 - 1,
        (absoluteOrigin.dy / screenSize.height) * 2 - 1
      );
      if (_celebrationAlignment != newAlignment) {
         // No need for setState here, as alignment is only used when _isCelebrating is true,
         // and _triggerCelebration calls setState anyway.
         _celebrationAlignment = newAlignment;
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    if (!mounted) return;

    // No need to calculate origin here anymore

    setState(() {
      _isCelebrating = true;
      // _celebrationAlignment is already calculated and stored
    });

    _celebrationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isCelebrating = false;
        });
      }
    });
  }

  @override
  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Stack(
      children: [
        // Main game content (Column)
        Column(
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
            SizedBox(height: GameConfig.defaultPadding * 1.5),
            Expanded(
              flex: 2,
              child: buildLetterGrid(gameState, audioService),
            ),
            SizedBox(height: GameConfig.defaultPadding),
          ],
        ),
        
        // Full screen celebration overlay
        if (_isCelebrating)
          Positioned.fill(
            child: IgnorePointer(
              child: ScaleTransition(
                // Use the pre-calculated alignment
                alignment: _celebrationAlignment, 
                scale: _celebrationScaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // Make it a circle emanating outwards
                    gradient: RadialGradient(
                      colors: [
                        // Make starting color more opaque
                        GameConfig.highlightColor.withOpacity(0.7), 
                        GameConfig.highlightColor.withOpacity(0.0),
                      ],
                      // Adjust stops for a sharper center and quicker fade
                      stops: const [0.0, 0.6], 
                    ),
                  ),
                ),
              ),
            ),
          ),
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