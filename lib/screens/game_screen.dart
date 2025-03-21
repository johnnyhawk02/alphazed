import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../widgets/image_drop_target.dart';
import '../widgets/letter_button.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _lottieController;
  late AnimationController _wrongAnimationController;
  bool _showCelebration = false;
  bool _showWrongAnimation = false;
  
  // Add a key to track the image container position
  final GlobalKey _imageContainerKey = GlobalKey();
  
  // Preloaded Lottie compositions
  LottieComposition? _celebrationAnimation;
  LottieComposition? _wrongAnimation;

  // Store the image container rect
  Rect? _imageRect;

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
    _wrongAnimationController = AnimationController(vsync: this);

    _controller.forward();
    
    // Preload Lottie animations
    _preloadAnimations();
    
    // Add a post frame callback to get the image position after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImageRect();
    });
  }
  
  // Preload Lottie animations
  Future<void> _preloadAnimations() async {
    try {
      // Load celebration animation
      _celebrationAnimation = await AssetLottie('assets/animations/correct.json').load();
      
      // Load wrong animation
      _wrongAnimation = await AssetLottie('assets/animations/wrong.json').load();
      
      // Set animation durations
      if (_celebrationAnimation != null) {
        _lottieController.duration = _celebrationAnimation!.duration;
      }
      
      if (_wrongAnimation != null) {
        _wrongAnimationController.duration = _wrongAnimation!.duration;
      }
    } catch (e) {
      print('Error loading animations: $e');
    }
  }

  // New method to get the position and size of the image container
  void _updateImageRect() {
    try {
      if (_imageContainerKey.currentContext != null) {
        final RenderBox box = _imageContainerKey.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        setState(() {
          _imageRect = Rect.fromLTWH(position.dx, position.dy, box.size.width, box.size.height);
        });
      }
    } catch (e) {
      print('Error updating image rect: $e');
    }
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

    if (_wrongAnimationController.isAnimating) {
      _wrongAnimationController.stop();
    }
    _wrongAnimationController.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Post frame callback to update image position on layout changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateImageRect();
        });
        
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                elevation: 1,
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
                    return const Center(
                      child: CircularProgressIndicator(),
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
            
            // Show animations positioned over the image if _imageRect is available
            if (_showCelebration && _celebrationAnimation != null && _imageRect != null)
              Positioned(
                left: _imageRect!.left,
                top: _imageRect!.top,
                width: _imageRect!.width,
                height: _imageRect!.height,
                child: Lottie(
                  composition: _celebrationAnimation,
                  controller: _lottieController,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            
            // Show animations positioned over the image if _imageRect is available
            if (_showWrongAnimation && _wrongAnimation != null && _imageRect != null)
              Positioned(
                left: _imageRect!.left,
                top: _imageRect!.top,
                width: _imageRect!.width,
                height: _imageRect!.height,
                child: Lottie(
                  composition: _wrongAnimation,
                  controller: _wrongAnimationController,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              
            // Fallback to centered animations if image position is not available
            if (_showCelebration && _celebrationAnimation != null && _imageRect == null)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Lottie(
                    composition: _celebrationAnimation,
                    controller: _lottieController,
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
            // Fallback to centered animations if image position is not available
            if (_showWrongAnimation && _wrongAnimation != null && _imageRect == null)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Lottie(
                    composition: _wrongAnimation,
                    controller: _wrongAnimationController,
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
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
              key: _imageContainerKey, // Add the key to the image container
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                boxShadow: [], // Removed shadows
              ),
              child: buildImageDropTarget(gameState, audioService), // Removed unnecessary ClipRRect
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
            key: _imageContainerKey, // Add the key to the image container
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              boxShadow: [], // Removed shadows
            ),
            child: buildImageDropTarget(gameState, audioService), // Removed unnecessary ClipRRect
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
          if (letter.toLowerCase() != gameState.currentItem!.firstLetter.toLowerCase()) {
            _playWrongAnimation();
            await audioService.playIncorrect();
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
              onDragSuccess: (success) async {
                if (success && gameState.currentOptions[index].toLowerCase() == gameState.currentItem!.firstLetter.toLowerCase()) {
                  _playCelebrationAnimation();
                  await Future.wait([
                    audioService.playAudio('assets/audio/other/bell.mp3'), // Play bell sound
                    audioService.playCongratulations(), // Play congratulations audio
                  ]);
                  
                  // Wait for animation to complete
                  if (_lottieController.isAnimating) {
                    await _lottieController.forward();
                  }
                  
                  if (mounted && context.mounted) {
                    await _controller.reverse();
                    gameState.nextImage();
                    _controller.forward();
                  }
                }
              },
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

  void _playWrongAnimation() {
    setState(() {
      _showWrongAnimation = true;
    });

    _wrongAnimationController.reset();
    _wrongAnimationController.forward().whenComplete(() {
      if (mounted) {
        _hideWrongAnimation();
      }
    });
  }

  void _hideWrongAnimation() {
    setState(() {
      _showWrongAnimation = false;
    });
  }
}