import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';
import '../mixins/interactive_animation_mixin.dart';

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

class _ImageDropTargetState extends State<ImageDropTarget> 
    with TickerProviderStateMixin, InteractiveAnimationMixin {
  
  // Constants for styling
  static const double _borderRadius = 36.0; // Increased from 24.0 to make corners even more rounded
  
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    initializeAnimation(
      duration: GameConfig.dropAnimationDuration,
      beginScale: 1.0,
      endScale: 1.05,
      vsync: this,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
  
  // Build the word label at the bottom
  Widget _buildWordLabel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha((0.3 * 255).toInt()), // Replaced withOpacity
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: GameConfig.defaultPadding,
        horizontal: GameConfig.defaultPadding * 1.5,
      ),
      child: Text(
        widget.item.word,
        style: GameConfig.wordTextStyle.copyWith(
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black.withAlpha((0.6 * 255).toInt()), // Replaced withOpacity
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // Build the hover indicator
  Widget _buildHoverIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.8 * 255).toInt()), // Replaced withOpacity
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()), // Subtle shadow
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
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
        animationController.forward();
        return true;
      },
      onLeave: (_) {
        setState(() => isHovering = false);
        animationController.reverse();
      },
      onAcceptWithDetails: (data) {
        setState(() => isHovering = false);
        animationController.reverse();
        widget.onLetterAccepted(data.data);
      },
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              boxShadow: [], // Removed shadows
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: GameConfig.fadeAnimationDuration,
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
                  
                  // Hover indicator
                  if (isHovering) Positioned.fill(child: _buildHoverIndicator()),
                  
                  // Word label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildWordLabel(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}