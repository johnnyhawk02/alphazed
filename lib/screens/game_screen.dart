import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _lottieController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      duration: GameConfig.fadeAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _lottieController = AnimationController(vsync: this);

    _controller.forward();
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();

    if (_lottieController.isAnimating) {
      _lottieController.stop();
    }
    _lottieController.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                centerTitle: true,
                title: Text(
                  'Alphabet Learning Game',
                  style: GameConfig.titleTextStyle,
                ),
              ),
              backgroundColor: Colors.transparent,
              body: Consumer2<GameState, AudioService>(
                builder: (context, gameState, audioService, _) {
                  if (gameState.currentItem == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(GameConfig.primaryButtonColor),
                      ),
                    );
                  }
                  return SafeArea(
                    child: FadeTransition(
                      opacity: _scaleAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: GameConfig.defaultPadding),
                          child: orientation == Orientation.portrait 
                            ? buildPortraitLayout(gameState, audioService)
                            : buildLandscapeLayout(gameState, audioService),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showCelebration)
              Positioned.fill(
                child: Lottie.asset(
                  'assets/animations/anim1.json',
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController.duration = composition.duration;
                    _lottieController.forward().whenComplete(() {
                      if (mounted) {
                        _hideCelebrationAnimation();
                      }
                    });
                  },
                  repeat: false,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        );
      }
    );
  }

  Widget buildPortraitLayout(GameState gameState, AudioService audioService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                child: buildImageDropTarget(gameState, audioService),
              ),
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

  Widget buildLandscapeLayout(GameState gameState, AudioService audioService) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              child: buildImageDropTarget(gameState, audioService),
            ),
          ),
        ),
        SizedBox(width: GameConfig.letterSpacing),
        Expanded(
          child: buildLetterGrid(gameState, audioService),
        ),
      ],
    );
  }

  Widget buildImageDropTarget(GameState gameState, AudioService audioService) {
    return Hero(
      tag: 'game_image_${gameState.currentItem!.imagePath}',
      child: ImageDropTarget(
        key: ValueKey(gameState.currentItem!.imagePath),
        item: gameState.currentItem!,
        onLetterAccepted: (letter) async {
          if (letter.toLowerCase() == gameState.currentItem!.firstLetter.toLowerCase()) {
            _playCelebrationAnimation();
            await audioService.playCongratulations();
            if (mounted && context.mounted) {
              _controller.reverse().then((_) {
                gameState.nextImage();
                _controller.forward();
              });
            }
          } else {
            await audioService.playIncorrect();
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Try Again!', style: GameConfig.bodyTextStyle.copyWith(color: Colors.white)),
                  backgroundColor: GameConfig.secondaryButtonColor.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget buildLetterGrid(GameState gameState, AudioService audioService) {
    return Center(
      child: Wrap(
        spacing: GameConfig.letterSpacing,
        runSpacing: GameConfig.letterSpacing,
        alignment: WrapAlignment.center,
        children: List.generate(
          gameState.currentOptions.length,
          (index) => AnimatedOpacity(
            duration: GameConfig.fadeAnimationDuration,
            opacity: index < gameState.visibleLetterCount && !gameState.isQuestionPlaying ? 1.0 : 0.0,
            child: LetterButton(
              key: ValueKey('letter_${gameState.currentOptions[index]}_$index'),
              letter: gameState.currentOptions[index],
              onTap: () => audioService.playLetter(gameState.currentOptions[index]),
              visible: index < gameState.visibleLetterCount && !gameState.isQuestionPlaying,
            ),
          ),
        ),
      ),
    );
  }

  void _playCelebrationAnimation() {
    setState(() {
      _showCelebration = true;
    });

    _lottieController.reset();
    _lottieController.forward().whenComplete(() {
      if (mounted) {
        _hideCelebrationAnimation();
      }
    });
  }

  void _hideCelebrationAnimation() {
    setState(() {
      _showCelebration = false;
    });
  }
}