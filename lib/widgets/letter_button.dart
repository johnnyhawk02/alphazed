import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatefulWidget {
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
  State<LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<LetterButton> {
  bool _wasSuccessfullyDragged = false;
  
  @override
  Widget build(BuildContext context) {
    // Always create the button container, even if not visible
    final buttonWidget = _buildLetterCircle(context);
    
    if (!widget.visible) {
      // Instead of returning an empty SizedBox, return a transparent button
      return Opacity(
        opacity: 0,
        child: buttonWidget,
      );
    }
    
    // If the letter was successfully dragged before, always show the empty circle
    if (_wasSuccessfullyDragged) {
      return const _EmptyLetterCircle();
    }
    
    return widget.draggable
        ? Draggable<String>(
            data: widget.letter,
            onDragEnd: (details) {
              if (details.wasAccepted) {
                setState(() {
                  _wasSuccessfullyDragged = true;
                });
                widget.onDragSuccess?.call(true);
              }
            },
            feedback: _buildLetterCircle(context, isForFeedback: true),
            childWhenDragging: const _EmptyLetterCircle(),
            child: GestureDetector(
              onTap: widget.onTap,
              child: buttonWidget,
            ),
          )
        : GestureDetector(
            onTap: widget.onTap,
            child: buttonWidget,
          );
  }
  
  Widget _buildLetterCircle(BuildContext context, {bool isForFeedback = false}) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.2;
    final double fontSize = buttonSize * 0.6;
    
    final bool isButtonActive = isForFeedback || widget.draggable;
    final bool showLetterText = isForFeedback || widget.colored;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: GameConfig.getLetterButtonDecoration(
          context, 
          isActive: isButtonActive
        ),
        child: Center(
          child: showLetterText 
            ? Text(
                widget.letter.toLowerCase(),
                style: GameConfig.letterTextStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.white,
                ),
              )
            : Opacity(
                opacity: 0.0,
                child: Text(
                  widget.letter.toLowerCase(),
                  style: GameConfig.letterTextStyle.copyWith(
                    fontSize: fontSize,
                  ),
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
    final double buttonSize = MediaQuery.of(context).size.width * 0.2;
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: GameConfig.getLetterButtonDecoration(context, isActive: false),
    );
  }
}