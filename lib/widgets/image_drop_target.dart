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

class _ImageDropTargetState extends State<ImageDropTarget> with SingleTickerProviderStateMixin {
  // Constants for styling
  static const double _borderRadius = 36.0;
  
  bool isHovering = false;
  bool isIncorrect = false;
  String? correctLetter; // Track the correct letter to display
  bool showWord = false; // Track if we should show the word
  bool isPressed = false; // Track if finger/mouse is pressed
  
  // Animation controller for the red flash effect
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  
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
  }
  
  @override
  void dispose() {
    _flashController.dispose();
    _audioService.dispose();
    super.dispose();
  }
  
  // Trigger the red flash effect
  void _flashImageRed() {
    setState(() {
      isIncorrect = true;
    });
    _flashController.reset();
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
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) {
        setState(() => isHovering = true);
        return true;
      },
      onLeave: (_) {
        setState(() => isHovering = false);
      },
      onAcceptWithDetails: (data) {
        setState(() => isHovering = false);
        
        // Check if the dropped letter is correct
        final isCorrect = data.data.toLowerCase() == widget.item.firstLetter.toLowerCase();
        if (isCorrect) {
          setState(() {
            correctLetter = data.data.toLowerCase();
          });
        } else {
          _flashImageRed();
        }
        
        widget.onLetterAccepted(data.data);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
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
                            style: GameConfig.letterTextStyle.copyWith(
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
                        child: Center(
                          child: Text(
                            widget.item.word,
                            style: GameConfig.wordTextStyle.copyWith(
                              fontSize: GameConfig.imageDropWordFontSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Image
                    Positioned.fill(
                      child: Opacity(
                        opacity: isHovering ? 0.7 : 1.0,
                        child: AspectRatio(
                          aspectRatio: 4/3,
                          child: Image.asset(
                            widget.item.imagePath,
                            fit: BoxFit.cover,
                          ),
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
    );
  }
}