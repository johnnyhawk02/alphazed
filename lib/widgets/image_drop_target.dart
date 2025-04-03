import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';
import '../services/theme_provider.dart';
import '../widgets/animation_overlay.dart'; // Import the animation overlay widget

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
  bool _showCorrectAnimation = false; // New state for showing the celebration animation
  
  // Get AudioService from the widget tree instead of creating a new instance
  AudioService? _getAudioService() {
    try {
      return Provider.of<AudioService>(context, listen: false);
    } catch (e) {
      return null;
    }
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
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // Check if device is likely an iPad (using aspect ratio and screen size)
        bool isIpad = mediaQuery.size.shortestSide >= 600 &&
                    (screenWidth / mediaQuery.size.height).abs() < 1.6;
        
        // Calculate width - use 70% of screen width for iPad, otherwise use available width
        final double targetWidth = isIpad 
            ? screenWidth * GameConfig.ipadImageWidthFactor 
            : constraints.maxWidth;
            
        // For 1:1 ratio, height should equal width
        final double containerHeight = targetWidth;
        
        // Main stack: DragTarget first, Confetti on top
        return Center(
          child: Stack(
            clipBehavior: Clip.none, // Allow character animation to extend outside bounds
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
                  
                  // Check if the dropped letter is correct
                  final isCorrect = data.data.toLowerCase() == widget.item.firstLetter.toLowerCase();
                  
                  // Only flash red for incorrect answers (no flash for correct answers)
                  if (!isCorrect) {
                    context.read<ThemeProvider>().flashIncorrect();
                  } else {
                    // Show celebration animation for correct answers
                    setState(() {
                      _showCorrectAnimation = true;
                    });

                    // Hide the animation after a delay
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      if (mounted) {
                        setState(() {
                          _showCorrectAnimation = false;
                        });
                      }
                    });
                  }
                  
                  // We don't set correctLetter anymore, even for correct answers
                  widget.onLetterAccepted(data.data);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: targetWidth,
                    height: containerHeight,
                    // Remove padding to allow image to take up full container
                    decoration: BoxDecoration(
                      // Remove border radius for edge-to-edge display
                    ),
                    // Modified: Keep ClipRRect only for overlays but not for the main container
                    child: Stack(
                      children: [
                        // Image - No ClipRRect to allow edge-to-edge display
                        Positioned.fill(
                          child: Opacity(
                            opacity: isHovering ? 0.7 : 1.0,
                            child: Image.asset(
                              widget.item.imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                print("Error loading image: ${widget.item.imagePath}\nError: $error");
                                // Provide a fallback display when image can't be loaded
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported,
                                            size: 60, color: Colors.grey.shade700),
                                        const SizedBox(height: 16),
                                        Text(
                                          widget.item.word,
                                          style: GameConfig.wordTextStyle.copyWith(
                                            fontSize: 36,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Hover indicator
                        if (isHovering) Positioned.fill(child: _buildHoverIndicator()),
                        
                        // Success animation overlay - positioned higher up on the image
                        if (_showCorrectAnimation)
                          AnimatedCharacter(
                            animationPath: 'assets/animations/correct.json',
                            size: targetWidth * 0.7, // Size relative to image
                            positionOffset: Offset(0, -containerHeight * 0.2), // Position it above the center of the image
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}