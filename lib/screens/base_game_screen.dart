import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';

// Common back button painter
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerY = size.height / 2;
    final arrowWidth = size.width * 0.6;
    
    final path = Path()
      ..moveTo(size.width * 0.75, centerY - arrowWidth / 2)
      ..lineTo(size.width * 0.25, centerY)
      ..lineTo(size.width * 0.75, centerY + arrowWidth / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract class BaseGameScreen extends StatefulWidget {
  final String title;

  const BaseGameScreen({
    super.key,
    required this.title,
  });

  @override
  BaseGameScreenState createState();
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends State<T>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _lottieController;
  late AnimationController _wrongAnimationController;
  bool _showCelebration = false;
  bool _showWrongAnimation = false;

  final GlobalKey _targetContainerKey = GlobalKey();
  LottieComposition? _celebrationAnimation;
  LottieComposition? _wrongAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimationControllers();
    _preloadAnimations();
    _updateTargetRectPostFrame();
  }

  void _initializeAnimationControllers() {
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
  }

  Future<void> _preloadAnimations() async {
    try {
      _celebrationAnimation = await AssetLottie('assets/animations/correct.json').load();
      _wrongAnimation = await AssetLottie('assets/animations/wrong.json').load();

      if (_celebrationAnimation != null) {
        _lottieController.duration = _celebrationAnimation!.duration;
      }
      if (_wrongAnimation != null) {
        _wrongAnimationController.duration = _wrongAnimation!.duration;
      }
    } catch (e) {
      // Handle animation loading errors silently
    }
  }

  void _updateTargetRectPostFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateTargetRect();
      }
    });
  }

  void _updateTargetRect() {
    if (!mounted) return;
    
    try {
      if (_targetContainerKey.currentContext != null) {
        final RenderBox box = _targetContainerKey.currentContext!.findRenderObject() as RenderBox;
        if (box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (mounted) {
            setState(() {
              _targetRect = Rect.fromLTWH(position.dx, position.dy, box.size.width, box.size.height);
            });
          }
        }
      }
    } catch (e) {
      // Handle errors silently
    }
  }

  @override
  void dispose() {
    _disposeAnimationControllers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _disposeAnimationControllers() {
    if (_controller.isAnimating) _controller.stop();
    _controller.dispose();

    if (_lottieController.isAnimating) _lottieController.stop();
    _lottieController.dispose();

    if (_wrongAnimationController.isAnimating) _wrongAnimationController.stop();
    _wrongAnimationController.dispose();
  }

  // Utility methods for animations
  void playCelebrationAnimation() {
    setState(() => _showCelebration = true);
    _lottieController.reset();
    _lottieController.forward().whenComplete(() {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  void playWrongAnimation() {
    setState(() => _showWrongAnimation = true);
    _wrongAnimationController.reset();
    _wrongAnimationController.forward().whenComplete(() {
      if (mounted) {
        setState(() => _showWrongAnimation = false);
      }
    });
  }

  // Layout methods that must be implemented by subclasses
  Widget buildPortraitLayout(GameState gameState, AudioService audioService);
  Widget buildLandscapeLayout(GameState gameState, AudioService audioService);
  Widget buildLetterGrid(GameState gameState, AudioService audioService);

  // Common app bar with back button
  PreferredSizeWidget buildGameAppBar() {
    return AppBar(
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
        (widget as BaseGameScreen).title,
        style: GameConfig.titleTextStyle,
      ),
    );
  }

  // Base build method that implements the common structure
  @override
  Widget build(BuildContext context) {
    _updateTargetRectPostFrame();
    
    return OrientationBuilder(
      builder: (context, orientation) {
        return Stack(
          children: [
            Scaffold(
              appBar: buildGameAppBar(),
              backgroundColor: Colors.transparent,
              body: Consumer2<GameState, AudioService>(
                builder: (context, gameState, audioService, _) {
                  if (gameState.currentItem == null) {
                    return const Center(child: CircularProgressIndicator());
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
            if (_showCelebration && _celebrationAnimation != null && _targetRect != null)
              _buildAnimationOverlay(_celebrationAnimation!, _lottieController, _targetRect!),
            if (_showWrongAnimation && _wrongAnimation != null && _targetRect != null)
              _buildAnimationOverlay(_wrongAnimation!, _wrongAnimationController, _targetRect!),
          ],
        );
      },
    );
  }

  Widget _buildAnimationOverlay(
    LottieComposition animation,
    AnimationController controller,
    Rect targetRect,
  ) {
    return Positioned(
      left: targetRect.left,
      top: targetRect.top,
      width: targetRect.width,
      height: targetRect.height,
      child: Lottie(
        composition: animation,
        controller: controller,
        repeat: false,
        fit: BoxFit.contain,
      ),
    );
  }

  // Utility getters for subclasses
  GlobalKey get targetContainerKey => _targetContainerKey;
  AnimationController get mainController => _controller;
  Animation<double> get scaleAnimation => _scaleAnimation;
}