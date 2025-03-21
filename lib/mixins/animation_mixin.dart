import 'package:flutter/material.dart';

// Refactor: Abstracted common animation logic into a mixin
mixin AnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;

  void initializeAnimation({required Duration duration, required TickerProvider vsync}) {
    animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}