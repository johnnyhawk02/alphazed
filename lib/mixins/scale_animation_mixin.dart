import 'package:flutter/material.dart';

mixin ScaleAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController scaleController;
  late final Animation<double> scaleAnimation;
  
  void initScaleAnimation({
    required Duration duration,
    double beginScale = 1.0,
    double endScale = 0.95,
    Curve curve = Curves.easeInOut,
  }) {
    scaleController = AnimationController(
      duration: duration,
      vsync: this,
    );

    scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: curve,
    ).drive(Tween<double>(
      begin: beginScale,
      end: endScale,
    ));
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }
}