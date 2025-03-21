import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../mixins/interactive_animation_mixin.dart';

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

class _LetterButtonState extends State<LetterButton> with TickerProviderStateMixin, InteractiveAnimationMixin {
  bool _isDragging = false;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    initializeAnimation(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
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
      onDragStarted: () {
        setState(() => _isDragging = true);
        animationController.forward();
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
          if (details.wasAccepted) {
            _isHidden = true;
            widget.onDragSuccess?.call(true);
          }
        });
        animationController.reverse();
      },
      onDraggableCanceled: (_, __) => animationController.reverse(),
      feedback: _buildLetterCircle(isForFeedback: true),
      childWhenDragging: const Opacity(
        opacity: 0.3,
        child: _EmptyLetterCircle(),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => animationController.forward(),
        onTapUp: (_) => animationController.reverse(),
        onTapCancel: () => animationController.reverse(),
        child: ScaleTransition(
          scale: scaleAnimation,
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