import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui; // For lerpDouble

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2; // For physics

import '../services/audio_service.dart'; // For sound effects

// --- Configuration ---
const double _dotBaseRadius = 5.0;
const double _dotSpacing = 28.0; // Distance between dot centers
const double _dotInteractionPulse = 0.8; // How much radius increases on touch (factor)
const double _margin = 30.0; // Margin around the grid

// Physics Parameters
const double _stiffness = 100.0; // Spring constant (k): Higher = faster return
const double _damping = 6.0; // Damping coefficient (c): Higher = less oscillation
const double _touchForce = 10000.0; // Repulsive force from touch
const double _touchRadius = 100.0; // Radius around touch point that affects dots
const double _maxSpeed = 800.0; // Speed limit for dots

// --- Helper Class for Dot State ---
class _Dot {
  final int id;
  final Vector2 homePosition; // Original grid position
  Vector2 currentPosition;
  Vector2 velocity;
  final Color baseColor; // Color when resting
  Color currentColor; // Color for drawing (can animate)

  final AnimationController interactionController;
  // Use late final for initialization in constructor body
  late final Animation<double> interactionAnimation;

  _Dot({
    required this.id,
    required this.homePosition,
    required this.baseColor,
    required TickerProvider vsync,
  })  : currentPosition = homePosition.clone(), // Start at home
        velocity = Vector2.zero(),
        currentColor = baseColor,
        // Initialize controller first in the initializer list
        interactionController = AnimationController(
            vsync: vsync, duration: const Duration(milliseconds: 500))
  {
      // Initialize animation in the constructor BODY, where 'this' is available
      interactionAnimation = CurvedAnimation(
          parent: interactionController, // Now it's safe to access
          curve: Curves.elasticOut // Bouncy pulse
      );

      // Add listener here as well
      interactionAnimation.addListener(() {
         // Can update currentColor here based on animation value if needed
         // currentColor = Color.lerp(baseColor, Colors.white, interactionAnimation.value * 0.6)!;
      });
  }


  void dispose() {
    interactionController.dispose();
  }

  // Apply disturbance (used on touch)
  void disturb() {
    if (!interactionController.isAnimating) { // Avoid restarting if already running
       interactionController.forward(from: 0.0); // Start the pulse animation
    }
  }
}

// --- Main Screen Widget ---
class DotSwishScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onComplete;

  const DotSwishScreen({
    Key? key,
    required this.audioService,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DotSwishScreen> createState() => _DotSwishScreenState();
}

class _DotSwishScreenState extends State<DotSwishScreen>
    with TickerProviderStateMixin {
  final List<_Dot> _dots = [];
  final math.Random _random = math.Random();
  Timer? _completionTimer;
  bool _showNextButton = false;
  bool _gridInitialized = false;

  late AnimationController _loopController;
  DateTime _lastUpdateTime = DateTime.now();

  Offset? _touchPoint; // Current position of the user's finger

  // Sound effect for swishing (rate-limited)
  final String _swishSoundPath = 'assets/audio/other/swish.mp3'; // Find or create a nice swish sound
  DateTime _lastSwishSoundTime = DateTime.now();
  final Duration _minSwishInterval = const Duration(milliseconds: 80);

  // Base colors for the gradient effect
  final Color _colorTopLeft = Colors.cyan.shade300;
  final Color _colorBottomRight = Colors.purple.shade300;
  final Color _flashColor = Colors.yellow.shade300; // Color for interaction pulse

  @override
  void initState() {
    super.initState();

    // Initialize grid after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if(mounted) {
          _initGrid();
          // Small delay before marking as initialized to ensure layout is stable? Or just set state.
          // await Future.delayed(Duration(milliseconds: 50));
          if (mounted) setState(() { _gridInitialized = true; });
       }
    });

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration doesn't matter
    )..repeat();

    _loopController.addListener(_updatePhysics);
     _lastUpdateTime = DateTime.now();

    // Timer to show "Next" button eventually
    _completionTimer = Timer(const Duration(seconds: 12), () { // Consider duration based on interaction
      if (mounted && !_showNextButton) {
        setState(() { _showNextButton = true; });
      }
    });
  }

  @override
  void dispose() {
    print("Disposing DotSwishScreen...");
    _completionTimer?.cancel();
    _loopController.removeListener(_updatePhysics);
    _loopController.dispose();
    for (var dot in _dots) {
      dot.dispose();
    }
    print("DotSwishScreen disposed.");
    super.dispose();
  }

  void _initGrid() {
     if (!mounted) return;
     _dots.clear();
     final Size screenSize = MediaQuery.of(context).size;
     if (screenSize.isEmpty || screenSize.width <= 0 || screenSize.height <=0) {
        print("Warning: Screen size invalid during grid init: $screenSize");
        // Optionally schedule a retry
        // Future.delayed(Duration(milliseconds: 100), () => _initGrid());
        return;
     }

     final double gridWidth = screenSize.width - (2 * _margin);
     final double gridHeight = screenSize.height - (2 * _margin);

     // Ensure calculated dimensions are positive
     if (gridWidth <= 0 || gridHeight <= 0) {
       print("Warning: Calculated grid dimensions invalid ($gridWidth x $gridHeight). Margin too large?");
       return;
     }

     final int numCols = math.max(1,(gridWidth / _dotSpacing)).floor();
     final int numRows = math.max(1,(gridHeight / _dotSpacing)).floor();

     // Calculate the actual center offset based on the integer number of dots
     final double actualGridWidth = (numCols -1) * _dotSpacing; // Width is between centers
     final double actualGridHeight = (numRows -1) * _dotSpacing; // Height is between centers
     final double offsetX = (screenSize.width - actualGridWidth) / 2.0;
     final double offsetY = (screenSize.height - actualGridHeight) / 2.0;

     int idCounter = 0;
     // Use numCols/Rows as the upper bound (e.g., 0 to numCols-1)
     for (int r = 0; r < numRows; r++) {
       for (int c = 0; c < numCols; c++) {
         final double x = offsetX + c * _dotSpacing;
         final double y = offsetY + r * _dotSpacing;
         final homePos = Vector2(x, y);

         // Calculate color based on normalized position (avoid div by zero if only 1 row/col)
         final double normX = (numCols > 1) ? c / (numCols - 1) : 0.5;
         final double normY = (numRows > 1) ? r / (numRows - 1) : 0.5;

         // More distinct gradient colors maybe?
         final Color colorStart = _colorTopLeft;
         final Color colorMidX = Colors.lightBlue.shade300; // Intermediate X
         final Color colorMidY = Colors.pink.shade200;   // Intermediate Y
         final Color colorEndX = Colors.deepOrange.shade300; // End X
         final Color colorEndY = _colorBottomRight;        // End Y

         // Bilinear interpolation (simplified)
         Color topLerp = Color.lerp(colorStart, colorEndX, normX)!;
         Color bottomLerp = Color.lerp(colorMidY, colorEndY, normX)!;
         Color finalColor = Color.lerp(topLerp, bottomLerp, normY)!;


         _dots.add(_Dot(
           id: idCounter++,
           homePosition: homePos,
           baseColor: finalColor, // Use gradient color
           vsync: this,
         ));
       }
     }
     print("Initialized ${_dots.length} dots in grid ($numCols x $numRows).");
  }


  void _updatePhysics() {
    if (!mounted || !_gridInitialized || _dots.isEmpty) return; // Ensure grid is ready

    final now = DateTime.now();
    final double dt = (now.difference(_lastUpdateTime).inMicroseconds / 1000000.0).clamp(0.0, 0.032);
    _lastUpdateTime = now;

    if (dt <= 0) return;

    final Vector2? touchVector = _touchPoint == null ? null : Vector2(_touchPoint!.dx, _touchPoint!.dy);
    const double touchRadiusSq = _touchRadius * _touchRadius;

    bool didDisturb = false; // Track if any dot was disturbed in this frame

    for (final dot in _dots) {
      // Calculate Forces
      final displacement = dot.homePosition - dot.currentPosition;
      final Vector2 springForce = displacement * _stiffness;
      final Vector2 dampingForce = dot.velocity * -_damping;

      Vector2 touchForceVector = Vector2.zero();
      if (touchVector != null) {
        final vecFromTouch = dot.currentPosition - touchVector;
        final double distSq = vecFromTouch.length2;
        if (distSq < touchRadiusSq && distSq > 1e-4) {
          final double distance = math.sqrt(distSq);
          final double normalizedDist = (distance / _touchRadius).clamp(0.0, 1.0); // 0 = close, 1 = edge
          // Stronger force closer to center, fades out - using easeOut curve shape
          final double forceFactor = 1.0 - normalizedDist * normalizedDist; // Inverse quadratic falloff
          final double forceMagnitude = _touchForce * forceFactor * forceFactor; // Make falloff sharper

          if (forceMagnitude > 0) { // Only apply force if magnitude is positive
            final Vector2 direction = vecFromTouch / distance;
            touchForceVector = direction * forceMagnitude;
          }

          // Only disturb if force is applied and not already animating strongly
          if (forceMagnitude > 1 && !dot.interactionController.isAnimating) {
             dot.disturb();
             didDisturb = true;
          }
        }
      }

      // Update Physics
      final Vector2 totalForce = springForce + dampingForce + touchForceVector;
      dot.velocity += totalForce * dt; // a = F/m (m=1) -> dv = a*dt = F*dt
      if (dot.velocity.length > _maxSpeed) {
        dot.velocity.normalize();
        dot.velocity.scale(_maxSpeed);
      }
      // Prevent minuscule movement when near home and slow
       if (displacement.length < 0.5 && dot.velocity.length < 1.0) {
          dot.velocity.setZero();
          dot.currentPosition.setFrom(dot.homePosition); // Snap home
       } else {
           dot.currentPosition += dot.velocity * dt;
       }


      // Update color based on animation value
       dot.currentColor = Color.lerp(dot.baseColor, _flashColor, dot.interactionAnimation.value)!;
    }

     // Rate-limit sound
     if (didDisturb && now.difference(_lastSwishSoundTime) > _minSwishInterval) {
        widget.audioService.playShortSoundEffect(_swishSoundPath, stopPreviousEffect: false)
          .catchError((e) => print("Error playing swish sound: $e")); // Add error handling
        _lastSwishSoundTime = now;
     }
  }

  // --- Touch Handlers ---
  void _handlePanStart(DragStartDetails details) {
     if (mounted) setState(() => _touchPoint = details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
      if (mounted) setState(() => _touchPoint = details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
      if (mounted) setState(() => _touchPoint = null);
  }

  void _handleTapDown(TapDownDetails details) {
     if (mounted) {
        final tapPos = details.localPosition;
        setState(() => _touchPoint = tapPos);
       _applyTapDisturbance(tapPos);
       // Keep touch point active briefly for visual feedback via physics loop
       Future.delayed(const Duration(milliseconds: 150), () {
         if (mounted && _touchPoint == tapPos) {
           setState(() => _touchPoint = null);
         }
       });
     }
  }

  // Applies instant disturbance and triggers animation for dots near tap
   void _applyTapDisturbance(Offset tapPos) {
        if (!mounted) return;
        final Vector2 touchVector = Vector2(tapPos.dx, tapPos.dy);
        const double touchRadiusSq = _touchRadius * _touchRadius * 1.2; // Slightly larger radius for tap impact?
        bool didDisturb = false;

        for (final dot in _dots) {
             final vecFromTouch = dot.currentPosition - touchVector;
             final double distSq = vecFromTouch.length2;
             if (distSq < touchRadiusSq && distSq > 1e-4) {
                 // Apply an immediate small velocity impulse on tap
                 if (distSq > 1) { // Avoid division by zero / huge force if exactly on top
                    final double impulseFactor = 50.0 * (1.0 - (math.sqrt(distSq) / (_touchRadius*1.1))); // Stronger impulse closer
                    dot.velocity += vecFromTouch.normalized() * impulseFactor.clamp(0.0, 100.0);
                 }

                 // Trigger the animation
                 dot.disturb();
                 didDisturb = true;
             }
        }
        // Play sound if disturbance occurred
        final now = DateTime.now();
        if (didDisturb && now.difference(_lastSwishSoundTime) > _minSwishInterval) {
            widget.audioService.playShortSoundEffect(_swishSoundPath, stopPreviousEffect: false)
             .catchError((e) => print("Error playing swish sound: $e"));
            _lastSwishSoundTime = now;
        }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background
      body: GestureDetector(
        onTapDown: _handleTapDown,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Grid Painter Layer
            if (_gridInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotPainter(dots: _dots, repaint: _loopController),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()), // Loading

            // NEXT WORD Button
            if (_showNextButton)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _completionTimer?.cancel();
                      widget.onComplete();
                    },
                    child: Container( /* ... Same Button Style ... */
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                       decoration: BoxDecoration( color: Colors.teal.shade400, borderRadius: BorderRadius.circular(30), boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.4), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4), ),], border: Border.all( color: Colors.white.withOpacity(0.6), width: 1.5)),
                       child: const Text( 'NEXT WORD', style: TextStyle( fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2, shadows: [ Shadow(offset: Offset(1.0, 1.0), blurRadius: 1.0, color: Colors.black38,),]),),
                    ),
                  ),
                ),
              ),

            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10, // Adjust for status bar
              left: 20,
              child: Container(
                decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, ),
                 child: Material( // For InkWell splash
                     color: Colors.transparent,
                     shape: const CircleBorder(),
                     child: InkWell(
                       customBorder: const CircleBorder(),
                       onTap: () { _completionTimer?.cancel(); widget.onComplete(); },
                       child: const Padding( padding: EdgeInsets.all(8.0), child: Icon(Icons.arrow_back, color: Colors.white, size: 30),),
                     ),
                 )
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Custom Painter for Dots ---
class _DotPainter extends CustomPainter {
  final List<_Dot> dots;
  final Paint _dotPaint = Paint();

  _DotPainter({required this.dots, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
     if (dots.isEmpty) return;

     // Consider anti-aliasing
     _dotPaint.isAntiAlias = true;

    for (final dot in dots) {
      final double interactionValue = dot.interactionAnimation.value;
      // Ensure radius doesn't shrink below base - pulse outwards only
      final double currentRadius = _dotBaseRadius * (1.0 + interactionValue * _dotInteractionPulse);

       _dotPaint.color = dot.currentColor; // Color already calculated in physics

      // Add a subtle shadow or outer glow? Maybe too performance intensive.
      // Example shadow (use sparingly):
      // if (interactionValue > 0.1) {
      //    canvas.drawCircle(Offset(dot.currentPosition.x, dot.currentPosition.y), currentRadius + 2, Paint()..color = dot.currentColor.withOpacity(0.3 * interactionValue)..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0));
      // }

      canvas.drawCircle(
          Offset(dot.currentPosition.x, dot.currentPosition.y),
          currentRadius.clamp(_dotBaseRadius*0.5, _dotBaseRadius*3), // Clamp radius range
          _dotPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) {
    // Driven by repaint Listenable. Length check is minimal overhead.
    return dots.length != oldDelegate.dots.length;
  }
}