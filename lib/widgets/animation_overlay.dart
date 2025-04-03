import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimationWidget extends StatelessWidget {
  final LottieComposition? composition;
  final AnimationController controller;

  const AnimationWidget({
    super.key,
    required this.composition,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie(
      composition: composition,
      controller: controller,
      repeat: false,
      fit: BoxFit.contain,
    );
  }
}

class AnimationOverlay extends StatelessWidget {
  final LottieComposition? composition;
  final AnimationController controller;
  final Rect? targetRect;
  final double scale; // Added scale parameter

  const AnimationOverlay({
    super.key,
    required this.composition,
    required this.controller,
    this.targetRect,
    this.scale = 1.0, // Default scale is 1.0
  });

  @override
  Widget build(BuildContext context) {
    if (composition == null) return const SizedBox.shrink();
    if (targetRect != null) {
      return Positioned(
        left: targetRect!.left,
        top: targetRect!.top,
        width: targetRect!.width * scale, // Apply scale to width
        height: targetRect!.height * scale, // Apply scale to height
        child: AnimationWidget(
          composition: composition,
          controller: controller,
        ),
      );
    }
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8 * scale, // Apply scale
        height: MediaQuery.of(context).size.height * 0.6 * scale, // Apply scale
        child: AnimationWidget(
          composition: composition,
          controller: controller,
        ),
      ),
    );
  }
}

class AnimatedCharacter extends StatefulWidget {
  // Animation asset path
  final String animationPath;
  // Duration for the animation to stay visible
  final Duration displayDuration;
  // Position offset from center
  final Offset positionOffset;
  // Size of the animation
  final double size;
  
  const AnimatedCharacter({
    Key? key,
    required this.animationPath,
    this.displayDuration = const Duration(milliseconds: 1500),
    this.positionOffset = const Offset(0, 0),
    this.size = 150,
  }) : super(key: key);

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation controller for the character
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Scale animation - pop in and then slightly shrink (fixed with proper curve)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // Changed from elasticOut to easeOut to avoid values outside 0.0-1.0 range
    ));
    
    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0, 
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
    
    // Start the animation
    _controller.forward();
    
    // Auto-remove after display duration
    if (widget.displayDuration != Duration.zero) {
      Future.delayed(widget.displayDuration, () {
        if (mounted) {
          _fadeOut();
        }
      });
    }
  }
  
  // Fade out animation before removing
  void _fadeOut() {
    _controller.reverse().then((_) {
      if (mounted) {
        // Use a callback if needed to notify when animation is done
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Center in parent + offset
      top: MediaQuery.of(context).size.height / 2 - widget.size / 2 + widget.positionOffset.dy,
      left: MediaQuery.of(context).size.width / 2 - widget.size / 2 + widget.positionOffset.dx,
      width: widget.size,
      height: widget.size,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Lottie.asset(
            widget.animationPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            repeat: false,
          ),
        ),
      ),
    );
  }
}