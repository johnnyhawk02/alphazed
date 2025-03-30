import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';

class ImageDropTarget extends StatefulWidget {
  final GameItem item;
  final Function(String) onLetterAccepted;
  
  const ImageDropTarget({
    super.key,
    required this.item,
    required this.onLetterAccepted,
  });
  
  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> with TickerProviderStateMixin {
  // Constants for styling
  static const double _borderRadius = 0.0;
  
  bool isHovering = false;
  bool isIncorrect = false;
  String? correctLetter; // Track the correct letter to display
  bool showWord = false; // Track if we should show the word
  bool isPressed = false; // Track if finger/mouse is pressed
  
  // Animation controller for the red flash effect
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  
  // Animation controller for the success scale effect (NEW)
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  // Audio service for playing word sounds
  final AudioService _audioService = AudioService();
  
  @override
  void initState() {
    super.initState();
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flashAnimation = ColorTween(
      begin: Colors.red.withOpacity(0.7),
      end: Colors.transparent,
    ).animate(_flashController)
      ..addListener(() {
        setState(() {
          // Update state when animation value changes
        });
      });
      
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isIncorrect = false;
        });
      }
    });

    // Scale Animation Setup (NEW)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400), // Duration for the scale effect
      vsync: this,
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ])
    // Animate directly from controller for debugging
    .animate(_scaleController);
    /* Original with Curve:
    .animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut, // Bouncy curve
    ));
    */
  }
  
  @override
  void dispose() {
    _flashController.dispose();
    _scaleController.dispose(); // Dispose the new controller
    _audioService.dispose();
    super.dispose();
  }
  
  // Trigger the red flash effect
  void _flashImageRed() {
    setState(() {
      isIncorrect = true;
    });
    _flashController.forward();
  }

  // Handle press down
  void _handleTapDown(TapDownDetails details) async {
    setState(() {
      isPressed = true;
      showWord = true;
    });
    
    // Play the word audio immediately on press
    await _audioService.playWord(widget.item.word);
  }

  // Handle press up
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      isPressed = false;
    });
    
    // Keep word visible for 1 second after release
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          showWord = false;
        });
      }
    });
  }

  // Handle tap cancel
  void _handleTapCancel() {
    setState(() {
      isPressed = false;
      showWord = false;
    });
  }
  
  // Build the hover indicator
  Widget _buildHoverIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.8 * 255).toInt()),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_circle_outline,
          size: 60,
          color: GameConfig.primaryButtonColor,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // For 1:1 ratio, height should equal width
        final double containerHeight = availableWidth;
        
        // Main stack: DragTarget first, Confetti on top
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // DragTarget containing the image/letter/word display
            DragTarget<String>(
              onWillAcceptWithDetails: (data) {
                setState(() => isHovering = true);
                return true;
              },
              onLeave: (_) {
                setState(() => isHovering = false);
              },
              onAcceptWithDetails: (data) {
                setState(() => isHovering = false);
                
                final isCorrect = data.data.toLowerCase() == widget.item.firstLetter.toLowerCase();
                if (isCorrect) {
                  setState(() {
                    correctLetter = data.data.toLowerCase();
                  });
                  _scaleController.forward(from: 0.0); // Keep local scale animation
                } else {
                  _flashImageRed();
                }
                
                widget.onLetterAccepted(data.data);
              },
              builder: (context, candidateData, rejectedData) {
                // Wrap the GestureDetector with ScaleTransition (NEW)
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    child: Container(
                      width: availableWidth,
                      height: containerHeight,
                      // Remove padding to allow image to take up full container
                      // padding: EdgeInsets.all(GameConfig.imageDropTargetPadding),
                      decoration: BoxDecoration(
                        // Remove border radius for edge-to-edge display
                        // borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      // Modified: Keep ClipRRect only for overlays but not for the main container
                      child: Stack(
                        children: [
                          // Show the correct letter on a blue background if matched
                          if (correctLetter != null)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      GameConfig.primaryButtonColor,
                                      GameConfig.primaryButtonColor.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    correctLetter!,
                                    style: GameConfig.letterButtonTextStyle.copyWith(
                                      fontSize: GameConfig.letterFontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          // Show the word when pressed or for 1 second after release
                          else if (showWord)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      GameConfig.primaryButtonColor.withOpacity(isPressed ? 0.8 : 1.0),
                                      GameConfig.primaryButtonColor.withOpacity(isPressed ? 0.6 : 0.8),
                                    ],
                                  ),
                                ),
                                // Use Padding and FittedBox for dynamic text sizing
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.contain, // Scale down to fit
                                      child: Text(
                                        widget.item.word,
                                        style: GameConfig.wordTextStyle.copyWith(
                                          // Remove fixed font size, FittedBox handles sizing
                                          // fontSize: GameConfig.imageDropWordFontSize, 
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center, 
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            // Image - No ClipRRect to allow edge-to-edge display
                            Positioned.fill(
                              child: Opacity(
                                opacity: isHovering ? 0.7 : 1.0,
                                child: Image.asset(
                                  widget.item.imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          
                          // Red flash overlay when incorrect
                          if (isIncorrect) Positioned.fill(
                            child: Container(
                              color: _flashAnimation.value,
                            ),
                          ),
                          
                          // Hover indicator
                          if (isHovering) Positioned.fill(child: _buildHoverIndicator()),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}