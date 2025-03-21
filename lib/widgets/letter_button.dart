import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool visible;
  
  const LetterButton({
    super.key,
    required this.letter,
    required this.onTap,
    this.visible = true,
  });

  @override
  State<LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<LetterButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    setState(() => _isDragging = true);
    _controller.forward();
  }

  void _handleDragEnd(DraggableDetails details) {
    setState(() => _isDragging = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return SizedBox(
        width: GameConfig.letterButtonSize,
        height: GameConfig.letterButtonSize,
      );
    }

    return Draggable<String>(
      data: widget.letter,
      onDragStarted: _handleDragStart,
      onDragEnd: _handleDragEnd,
      onDraggableCanceled: (_, __) => _controller.reverse(),
      feedback: _buildLetterCircle(isForFeedback: true),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildLetterCircle(),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _buildLetterCircle(),
        ),
      ),
    );
  }

  Widget _buildLetterCircle({bool isForFeedback = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: GameConfig.letterButtonSize,
        height: GameConfig.letterButtonSize,
        decoration: GameConfig.getLetterButtonDecoration(isActive: !_isDragging || isForFeedback),
        child: Center(
          child: Text(
            widget.letter.toLowerCase(),
            style: GameConfig.letterTextStyle,
          ),
        ),
      ),
    );
  }
}