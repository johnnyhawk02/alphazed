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
    if (!widget.visible) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
        height: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
      );
    }
    
    // If the letter was successfully dragged before, always show the empty circle
    if (_wasSuccessfullyDragged) {
      return _EmptyLetterCircle();
    }
    
    return widget.draggable
        ? Draggable<String>(
            data: widget.letter,
            onDragEnd: (details) {
              if (details.wasAccepted) {
                // Mark as successfully dragged and call the callback
                setState(() {
                  _wasSuccessfullyDragged = true;
                });
                widget.onDragSuccess?.call(true);
              }
            },
            feedback: _buildLetterCircle(context, isForFeedback: true),
            childWhenDragging: const _EmptyLetterCircle(),
            child: GestureDetector(
              onTap: widget.onTap, // Play letter sound
              child: _buildLetterCircle(context),
            ),
          )
        : GestureDetector(
            onTap: widget.onTap, // Play letter sound
            child: _buildLetterCircle(context),
          );
  }
  
  Widget _buildLetterCircle(BuildContext context, {bool isForFeedback = false}) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.2; // 20% of screen width
    final double fontSize = buttonSize * 0.6; // Set font size to 60% of button size
    
    // Show the letter text when colored (audio played), but only change to blue when draggable
    // This way, letters appear on grey circles when audio plays, then turn blue when active
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
                opacity: 0.0, // Force 0% opacity
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
    final double buttonSize = MediaQuery.of(context).size.width * 0.2; // 20% of screen width
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: GameConfig.getLetterButtonDecoration(context, isActive: false),
    );
  }
}