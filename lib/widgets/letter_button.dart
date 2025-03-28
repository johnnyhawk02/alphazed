import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  final bool visible;
  final bool colored;
  final bool draggable;
  final ValueChanged<bool>? onDragSuccess;
  
  const LetterButton({
    super.key,
    required this.letter,
    required this.onTap,
    this.visible = true,
    this.colored = false,
    this.draggable = false,
    this.onDragSuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
        height: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
      );
    }

    return draggable
        ? Draggable<String>(
            data: letter,
            onDragEnd: (details) {
              if (details.wasAccepted) {
                onDragSuccess?.call(true);
              }
            },
            feedback: _buildLetterCircle(context, isForFeedback: true),
            childWhenDragging: const _EmptyLetterCircle(),
            child: GestureDetector(
              onTap: onTap, // Play letter sound
              child: _buildLetterCircle(context),
            ),
          )
        : GestureDetector(
            onTap: onTap, // Play letter sound
            child: _buildLetterCircle(context),
          );
  }

  Widget _buildLetterCircle(BuildContext context, {bool isForFeedback = false}) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.2; // 20% of screen width
    final double fontSize = buttonSize * 0.6; // Set font size to 60% of button size
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: GameConfig.getLetterButtonDecoration(
          context, 
          isActive: isForFeedback || colored
        ),
        child: Center(
          child: Text(
            letter.toLowerCase(),
            style: colored 
              ? GameConfig.letterTextStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.white,
                )
              : GameConfig.letterTextStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLetterCircle extends StatelessWidget {
  const _EmptyLetterCircle();

  @override
  Widget build(BuildContext context) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.2; // 20% of screen width
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: GameConfig.getLetterButtonDecoration(context, isActive: false),
    );
  }
}