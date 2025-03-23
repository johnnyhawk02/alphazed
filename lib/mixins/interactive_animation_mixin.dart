import 'package:flutter/material.dart';

mixin InteractiveAnimationMixin<T extends StatefulWidget> on State<T> {
  late final AnimationController animationController;
  late final Animation<double> scaleAnimation;

  void initializeAnimation({
    required Duration duration,
    double beginScale = 1.0,
    double endScale = 0.95,
    Curve curve = Curves.easeInOut,
    required TickerProvider vsync,
  }) {
    animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: curve,
    ).drive(Tween<double>(
      begin: beginScale,
      end: endScale,
    ));
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}