import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  final bool visible;

  const LetterButton({
    Key? key,
    required this.letter,
    required this.onTap,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return SizedBox(
        width: GameConfig.letterButtonSize,
        height: GameConfig.letterButtonSize,
      );
    }

    return Draggable<String>(
      data: letter,
      feedback: _buildLetterCircle(isForFeedback: true),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: GameConfig.fadeAnimationDuration,
          opacity: 1.0,
          child: _buildLetterCircle(),
        ),
      ),
    );
  }

  Widget _buildLetterCircle({bool isForFeedback = false}) {
    return Material(
      color: Colors.transparent,
      child: CircleAvatar(
        radius: GameConfig.letterButtonRadius,
        backgroundColor: GameConfig.primaryButtonColor,
        child: Text(
          letter.toLowerCase(),
          style: GameConfig.letterTextStyle.copyWith(
            color: isForFeedback ? Colors.blue : Colors.black,
          ),
        ),
      ),
    );
  }
}