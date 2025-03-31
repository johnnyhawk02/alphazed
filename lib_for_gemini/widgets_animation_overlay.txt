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