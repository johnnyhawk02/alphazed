import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool visible;
  final ValueChanged<bool>? onDragSuccess;  // Add callback for successful drops
  
  const LetterButton({
    super.key,
    required this.letter,
    required this.onTap,
    this.visible = true,
    this.onDragSuccess,
  });

  @override
  State<LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<LetterButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 150),
    vsync: this,
  );

  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  ).drive(Tween<double>(
    begin: 1.0,
    end: 0.95,
  ));

  bool _isDragging = false;
  bool _isHidden = false;

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
    setState(() {
      _isDragging = false;
      if (details.wasAccepted) {
        _isHidden = true;
        if (widget.onDragSuccess != null) {
          widget.onDragSuccess!(true);
        }
      }
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || _isHidden) {
      return const SizedBox(
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
      childWhenDragging: const Opacity(
        opacity: 0.3,
        child: _EmptyLetterCircle(),
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

class _EmptyLetterCircle extends StatelessWidget {
  const _EmptyLetterCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GameConfig.letterButtonSize,
      height: GameConfig.letterButtonSize,
      decoration: GameConfig.getLetterButtonDecoration(isActive: true),
    );
  }
}