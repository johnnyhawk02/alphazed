import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/game_state.dart';
import '../widgets/letter_button.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';

class LetterToLetterMatch extends StatefulWidget {
  const LetterToLetterMatch({super.key});

  @override
  State<LetterToLetterMatch> createState() => _LetterToLetterMatchState();
}

class _LetterToLetterMatchState extends State<LetterToLetterMatch> with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _lottieController;
  late AnimationController _wrongAnimationController;
  bool _showCelebration = false;
  bool _showWrongAnimation = false;
  
  // Add a key to track the letter container position
  final GlobalKey _letterContainerKey = GlobalKey();
  
  // Preloaded Lottie compositions
  LottieComposition? _celebrationAnimation;
  LottieComposition? _wrongAnimation;

  // Store the letter container rect
  Rect? _letterRect;

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
    
    // Add a post frame callback to get the letter position after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLetterRect();
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
      // Handle animation loading errors
    }
  }

  // Method to get the position and size of the letter container
  void _updateLetterRect() {
    // Add check to ensure widget is still mounted before accessing context
    if (!mounted) return;
    
    try {
      if (_letterContainerKey.currentContext != null) {
        final RenderBox box = _letterContainerKey.currentContext!.findRenderObject() as RenderBox;
        if (box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (mounted) {
            setState(() {
              _letterRect = Rect.fromLTWH(position.dx, position.dy, box.size.width, box.size.height);
            });
          }
        }
      }
    } catch (e) {
      // Handle errors
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
        // Post frame callback to update letter position on layout changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateLetterRect();
          }
        });
        
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                elevation: 1,
                backgroundColor: Colors.transparent,
                centerTitle: true,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: EdgeInsets.all(1),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GameConfig.primaryButtonColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: ArrowPainter(),
                    ),
                  ),
                ),
                title: Text(
                  'Letter Matching',
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
            
            // Show animations positioned over the letter if _letterRect is available
            if (_showCelebration && _celebrationAnimation != null && _letterRect != null)
              Positioned(
                left: _letterRect!.left,
                top: _letterRect!.top,
                width: _letterRect!.width,
                height: _letterRect!.height,
                child: Lottie(
                  composition: _celebrationAnimation,
                  controller: _lottieController,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            
            // Show wrong animations positioned over the letter
            if (_showWrongAnimation && _wrongAnimation != null && _letterRect != null)
              Positioned(
                left: _letterRect!.left,
                top: _letterRect!.top,
                width: _letterRect!.width,
                height: _letterRect!.height,
                child: Lottie(
                  composition: _wrongAnimation,
                  controller: _wrongAnimationController,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              
            // Fallback to centered animations if letter position is not available
            if (_showCelebration && _celebrationAnimation != null && _letterRect == null)
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
              
            // Fallback to centered animations if letter position is not available
            if (_showWrongAnimation && _wrongAnimation != null && _letterRect == null)
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
              key: _letterContainerKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
                boxShadow: [],
              ),
              child: buildLetterDropTarget(gameState, audioService),
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
            key: _letterContainerKey,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius * 2),
              boxShadow: [],
            ),
            child: buildLetterDropTarget(gameState, audioService),
          ),
        ),
        SizedBox(width: GameConfig.letterSpacing),
        Expanded(
          child: buildLetterGrid(gameState, audioService),
        ),
      ],
    );
  }

  Widget buildLetterDropTarget(GameState gameState, AudioService audioService) {
    final targetLetter = gameState.currentItem!.firstLetter.toUpperCase();
    
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) {
        return true;
      },
      onAcceptWithDetails: (data) async {
        final droppedLetter = data.data;
        if (droppedLetter.toLowerCase() != targetLetter.toLowerCase()) {
          _playWrongAnimation();
          await audioService.playIncorrect();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(GameConfig.defaultBorderRadius),
            border: Border.all(
              color: Colors.blue.shade300,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(32.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              targetLetter,
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.bold,
                color: GameConfig.primaryButtonColor,
              ),
            ),
          ),
        );
      },
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
                    audioService.playAudio('assets/audio/other/bell.mp3'),
                    audioService.playCongratulations(),
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

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate points for a centered arrow
    final centerY = size.height / 2;
    final arrowWidth = size.width * 0.6;
    
    // Start from right side, go to left, then back up
    final path = Path()
      ..moveTo(size.width * 0.75, centerY - arrowWidth / 2) // Start top of arrow head
      ..lineTo(size.width * 0.25, centerY) // To arrow point
      ..lineTo(size.width * 0.75, centerY + arrowWidth / 2); // To bottom of arrow head

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}