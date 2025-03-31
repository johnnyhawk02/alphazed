import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../services/audio_service.dart'; // Assuming AudioService path

// --- Helper Data Classes ---

class _Star {
  final Offset position;
  final double size;
  final double opacity;

  _Star({required this.position, required this.size, required this.opacity});
}

class _Satellite {
  final Offset startPos;
  final Offset endPos;
  final double size;
  final Duration duration; // Duration for one pass
  final Duration startDelay; // Delay before first appearance

  _Satellite({
    required this.startPos,
    required this.endPos,
    required this.size,
    required this.duration,
    required this.startDelay,
  });
}

class _ShootingStar {
  final int id;
  final Offset startPos;
  final Offset endPos;
  final AnimationController controller;
  final Function(int) onComplete;
  final Color color;
  final double thickness;

  _ShootingStar({
    required this.id,
    required this.startPos,
    required this.endPos,
    required this.controller,
    required this.onComplete,
    required this.color,
    required this.thickness,
  }) {
     // Status listener setup remains the same
     controller.addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         onComplete(id);
       }
     });
  }
}


// --- Main Widget ---

class FireworksScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onComplete;

  const FireworksScreen({
    Key? key,
    required this.audioService,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FireworksScreen> createState() => _FireworksScreenState();
}

class _FireworksScreenState extends State<FireworksScreen>
    with TickerProviderStateMixin {
  // --- State Variables ---
  final List<_Burst> _bursts = [];
  final Random _random = Random();
  Timer? _completionTimer;

  // Text Animation
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;

  // Background Elements
  List<_Star> _stars = [];
  List<_Satellite> _satellites = [];
  List<_ShootingStar> _shootingStars = [];

  // Background Animation Controllers
  late AnimationController _satelliteController;
  Timer? _shootingStarTimer;


  final List<String> _fireworkSounds = [
    'assets/audio/other/explosion.mp3',
    // Add more sound paths here
  ];

  @override
  void initState() {
    super.initState();

    // --- Text Animation ---
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(_textAnimationController);
    _textOpacityAnimation = TweenSequence<double>([
       TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
       TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_textAnimationController);
    _textAnimationController.forward();

    // --- Completion Timer ---
    _completionTimer = Timer(const Duration(seconds: 10), () { // Duration set to 10s
      if (mounted) widget.onComplete();
    });

    // --- Initialize Background Elements ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Use try-catch in case context becomes invalid during async gap
      try {
          final size = MediaQuery.of(context).size;
          _generateStars(size);
          _generateSatellites(size);
          if (mounted) setState(() {}); // Trigger rebuild to paint background
      } catch (e) {
          print("Error during background initialization: $e");
      }
    });

    // --- Satellite Animation ---
    _satelliteController = AnimationController(
      duration: const Duration(seconds: 60), // Long duration for slow movement
      vsync: this,
    )..repeat(); // Satellites loop indefinitely

    // --- Shooting Star Spawner ---
    _shootingStarTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
       if (mounted && _random.nextDouble() < 0.25) { // ~25% chance every 1.5s
           try {
              // Check mounted again just before accessing context
              if (mounted && context.findRenderObject()?.attached == true) {
                 final size = MediaQuery.of(context).size;
                 _addShootingStar(size);
              }
           } catch (e) {
             print("Error accessing context in shooting star timer: $e");
             timer.cancel(); // Stop timer if context is bad
           }
       }
    });

    // --- Initial Bursts (Keep these) ---
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         try {
             final size = MediaQuery.of(context).size;
             _addBurst(Offset(size.width / 2, size.height / 3));
             Future.delayed(const Duration(milliseconds: 300), () { if(mounted) _addBurst(Offset(size.width * 0.3, size.height * 0.6)); });
             Future.delayed(const Duration(milliseconds: 600), () { if(mounted) _addBurst(Offset(size.width * 0.7, size.height * 0.4)); });
         } catch (e) {
            print("Error during initial burst setup: $e");
         }
       }
     });
  }

  @override
  void dispose() {
    print("FireworksScreen disposing..."); // Debug log
    _completionTimer?.cancel();
    _shootingStarTimer?.cancel(); // Stop the spawner

    // Use try-catch for controller disposals as they might already be disposed
    try { _textAnimationController.dispose(); } catch (e) { /*print("Error disposing text controller: $e");*/ }
    try { _satelliteController.dispose(); } catch (e) { /*print("Error disposing satellite controller: $e");*/ }

    // Dispose all active burst controllers
    print("Disposing ${_bursts.length} burst controllers...");
    for (var burst in List.from(_bursts)) {
       try { burst.controller.dispose(); } catch (e) { /* print("Error disposing burst controller (id ${burst.id}): $e"); */ }
    }
    _bursts.clear();

    // Dispose all active shooting star controllers
    print("Disposing ${_shootingStars.length} shooting star controllers...");
    for (var star in List.from(_shootingStars)) {
        try { star.controller.dispose(); } catch (e) { /* print("Error disposing shooting star controller (id ${star.id}): $e"); */ }
    }
    _shootingStars.clear();
    print("FireworksScreen dispose complete.");
    super.dispose();
  }

  // --- Background Element Generation ---

  void _generateStars(Size size) {
    if (!mounted) return; // Check mounted
    _stars = List.generate(150, (index) { // Number of stars
      return _Star(
        position: Offset(_random.nextDouble() * size.width, _random.nextDouble() * size.height),
        size: _random.nextDouble() * 1.5 + 0.5, // Size range
        opacity: _random.nextDouble() * 0.5 + 0.3, // Opacity range
      );
    });
  }

  void _generateSatellites(Size size) {
     if (!mounted) return; // Check mounted
     _satellites = [
       _Satellite(
          startPos: Offset(-20, size.height * 0.2), endPos: Offset(size.width + 20, size.height * 0.4),
          size: 2.0, duration: const Duration(seconds: 70), startDelay: const Duration(seconds: 2)
       ),
       _Satellite(
          startPos: Offset(size.width * 0.3, -10), endPos: Offset(size.width * 0.3 + (_random.nextDouble() -0.5) * 50 , size.height + 10),
          size: 1.5, duration: const Duration(seconds: 50), startDelay: const Duration(seconds: 5)
       ),
       _Satellite(
          startPos: Offset(size.width + 15, size.height * 0.8), endPos: Offset(-15, size.height * 0.1),
          size: 2.5, duration: const Duration(seconds: 60), startDelay: Duration.zero
       ),
    ];
  }

  void _addShootingStar(Size size) {
      if (!mounted) return; // Check at the beginning

      final bool fromTop = _random.nextBool();
      final bool fromLeft = _random.nextBool();
      double startX, startY, endX, endY;
      const margin = 50.0;

      if (fromTop) {
         startY = -margin; endY = size.height * (_random.nextDouble() * 0.5 + 0.3);
         startX = _random.nextDouble() * size.width;
         endX = fromLeft ? startX - (size.width * 0.5 + _random.nextDouble() * size.width * 0.5)
                        : startX + (size.width * 0.5 + _random.nextDouble() * size.width * 0.5);
      } else {
         startY = size.height + margin; endY = size.height * (_random.nextDouble() * 0.5);
         startX = _random.nextDouble() * size.width;
         endX = fromLeft ? startX - (size.width * 0.5 + _random.nextDouble() * size.width * 0.5)
                        : startX + (size.width * 0.5 + _random.nextDouble() * size.width * 0.5);
      }
      if ((startX - endX).abs() < size.width * 0.3) {
         endX = fromLeft ? startX - size.width * 0.5 : startX + size.width * 0.5;
      }

      AnimationController? controller; // Declare as nullable
      try {
        // Check mounted again before creating controller using 'this' as TickerProvider
        if (!mounted) return;
        controller = AnimationController(
           duration: Duration(milliseconds: 600 + _random.nextInt(600)),
           vsync: this,
        );

        final star = _ShootingStar(
           id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000),
           startPos: Offset(startX, startY),
           endPos: Offset(endX, endY),
           controller: controller, // Pass the non-null controller
           color: Colors.white.withOpacity(0.8),
           thickness: _random.nextDouble() * 1.5 + 1.0,
           onComplete: (id) {
              // Check mounted inside the callback
              if (mounted) {
                 setState(() { _shootingStars.removeWhere((s) => s.id == id); });
              }
              // Controller disposal is handled by the main dispose method
           },
        );

        if (mounted) { // Check mounted before setState
          setState(() { _shootingStars.add(star); });
          controller.forward(); // Start animation only if added successfully
        } else {
          controller.dispose(); // Dispose if not mounted after creation
        }

      } catch (e) {
         print("Error creating/starting shooting star animation: $e");
         controller?.dispose(); // Ensure controller is disposed on error
      }
   }


  // --- Event Handlers & Burst Logic ---

  void _handleTap(TapDownDetails details) {
    if (!mounted) return;
    _addBurst(details.localPosition);
    _playRandomFireworkSound();
  }

   void _playRandomFireworkSound() {
     if (!mounted || _fireworkSounds.isEmpty) return;
     try {
       final soundPath = _fireworkSounds[_random.nextInt(_fireworkSounds.length)];
       widget.audioService.playShortSoundEffect(soundPath, stopPreviousEffect: false);
     } catch(e) {
       print("Error playing firework sound: $e");
     }
   }

  void _addBurst(Offset position) {
    if (!mounted) return; // Check mounted at start

    AnimationController? controller; // Declare nullable
    try {
        // Check mounted again before accessing 'this' for vsync
        if (!mounted) return;
        controller = AnimationController(
          duration: const Duration(milliseconds: 1200),
          vsync: this,
        );

        final burst = _Burst(
          id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000),
          position: position,
          controller: controller, // Pass non-null controller
          particleCount: 40 + _random.nextInt(40),
          maxDistance: 80 + _random.nextDouble() * 80,
          baseColor: Colors.primaries[_random.nextInt(Colors.primaries.length)],
          random: _random,
          onComplete: (id) {
             // Check mounted inside callback
            if (mounted) {
              setState(() { _bursts.removeWhere((b) => b.id == id); });
            }
            // Controller disposal handled by main dispose
          },
        );

      if (mounted) { // Check mounted before setState
         setState(() { _bursts.add(burst); });
         controller.forward(); // Start animation only if added successfully
      } else {
         controller.dispose(); // Dispose if state changed before starting
      }
    } catch (e) {
       print("Error creating/starting burst animation: $e");
       controller?.dispose(); // Ensure controller disposed on error
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
             // --- Background Layer ---
             CustomPaint(
                 painter: _BackgroundPainter(
                    stars: _stars,
                    satellites: _satellites,
                    // Pass copy for safety during paint phase
                    shootingStars: List.from(_shootingStars),
                    satelliteController: _satelliteController, // Pass controller
                 ),
                 size: Size.infinite,
              ),

            // --- Particle Bursts Layer ---
             if (_bursts.isNotEmpty)
                 CustomPaint(
                    // Pass copy for safety during paint phase
                    painter: _FireworksPainter(bursts: List.from(_bursts)),
                    size: Size.infinite,
                 ),

            // --- Animated Text Layer ---
            Center(
              child: FadeTransition(
                opacity: _textOpacityAnimation,
                child: ScaleTransition(
                  scale: _textScaleAnimation,
                  child: Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 70,
                      color: Colors.yellow[600],
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow( offset: Offset(0, 0), blurRadius: 15.0, color: Colors.orangeAccent),
                        Shadow( offset: Offset(2.0, 2.0), blurRadius: 4.0, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Burst Data Class (_Burst) ---
class _Burst {
  final int id;
  final Offset position;
  final AnimationController controller;
  final Function(int) onComplete;
  final int particleCount;
  final double maxDistance;
  final Color baseColor;
  final Random random;
  late List<_Particle> particles;
  bool _listenerAdded = false;

  _Burst({
    required this.id, required this.position, required this.controller, required this.onComplete,
    required this.particleCount, required this.maxDistance, required this.baseColor, required this.random,
  }) {
    _generateParticles();
    _addStatusListenerOnce(); // Add listener immediately
  }

  // Safely add listener only once
  void _addStatusListenerOnce(){
     if (!_listenerAdded) {
        try {
          // No need to check vsync/ticker, just add the listener.
          // If controller is disposed, addStatusListener might throw, caught below.
          controller.addStatusListener(_statusListener);
          _listenerAdded = true;
        } catch (e) {
          print("Error adding status listener: $e");
        }
     }
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onComplete(id);
       _removeStatusListenerOnce(); // Safely remove listener
    }
  }

   // Safely remove listener only once
   void _removeStatusListenerOnce() {
     if (_listenerAdded) {
       try {
         controller.removeStatusListener(_statusListener);
         _listenerAdded = false;
       } catch (e) {
         // Ignore errors, likely controller already disposed
         _listenerAdded = false; // Assume removed
       }
     }
   }

  void _generateParticles() {
    particles = List.generate(particleCount, (index) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * maxDistance;
      final particleColor = HSLColor.fromColor(baseColor)
          .withLightness((random.nextDouble() * 0.4) + 0.4)
          .withSaturation((random.nextDouble() * 0.5) + 0.5)
          .toColor();
      final lifetimeFactor = 0.8 + random.nextDouble() * 0.4;
      return _Particle(
        angle: angle, distance: distance, color: particleColor,
        size: 4.0 + random.nextDouble() * 6.0, lifetimeFactor: lifetimeFactor
      );
    });
  }
}

// --- Particle Data Class (_Particle) ---
class _Particle {
  final double angle; final double distance; final Color color; final double size; final double lifetimeFactor;
  _Particle({required this.angle, required this.distance, required this.color, required this.size, required this.lifetimeFactor });
}

// --- Fireworks Painter (_FireworksPainter) ---
class _FireworksPainter extends CustomPainter {
  final List<_Burst> bursts;
  final Paint _paint = Paint();
   // Repaint when controllers change
   _FireworksPainter({required this.bursts}) : super(repaint: Listenable.merge(
       bursts.map((b) => b.controller).toList()
     ));

  @override void paint(Canvas canvas, Size size) {
     if (bursts.isEmpty) return;
     for (final burst in bursts) {
        // It's possible the controller is disposed between the time
        // the listener triggers repaint and the paint method runs.
        // Use try-catch for safety.
        try {
           // Check status instead of isDisposed
           if (burst.controller.status == AnimationStatus.dismissed) continue;

           final progress = burst.controller.value;
           for (final particle in burst.particles) {
              final curveProgress = Curves.easeOutCubic.transform(progress);
              final currentDistance = particle.distance * curveProgress;
              final dx = burst.position.dx + cos(particle.angle) * currentDistance;
              final gravityEffect = pow(progress, 2) * 150 * particle.lifetimeFactor;
              final dy = burst.position.dy + sin(particle.angle) * currentDistance + gravityEffect;
              final currentPos = Offset(dx, dy);
              final opacity = max(0.0, (1.0 - (progress * 1.5 / particle.lifetimeFactor)).clamp(0.0, 1.0));
              if (opacity <= 0) continue;
              _paint.color = particle.color.withOpacity(opacity);
              canvas.drawCircle(currentPos, particle.size * (1.0 - progress * 0.5), _paint);
           }
        } catch (e) {
           // Log error if accessing disposed controller's value/status fails
           // print("Error painting burst (likely controller disposed): $e");
        }
     }
  }
  @override bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
     // Repaint if list length changed OR any controller is still animating
     // Check status instead of isAnimating for more robustness? isAnimating might be false after completion.
     // Relying on Listenable.merge in the constructor is generally preferred.
     return bursts.length != oldDelegate.bursts.length || bursts.any((b) => b.controller.isAnimating);
  }
}


// --- Background Painter ---
class _BackgroundPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Satellite> satellites;
  final List<_ShootingStar> shootingStars;
  final AnimationController satelliteController;

  _BackgroundPainter({
    required this.stars,
    required this.satellites,
    required this.shootingStars,
    required this.satelliteController,
  }) : super(repaint: Listenable.merge([ // Merge active controllers
         satelliteController,
         ...shootingStars.map((s) => s.controller) // Pass controllers directly
       ]));

  final Paint _starPaint = Paint();
  final Paint _moonPaint = Paint()..color = Colors.grey.shade300.withOpacity(0.7);
  final Paint _satellitePaint = Paint()..color = Colors.blueGrey.shade200.withOpacity(0.9);
  final Paint _shootingStarPaint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw Stars ---
    double twinkleFactor = 0.75; // Default value
    try {
       // Check status instead of isDisposed
       if (satelliteController.status != AnimationStatus.dismissed) {
          twinkleFactor = (0.5 + (sin(satelliteController.value * 2 * pi * 2) + 1) / 4);
       }
    } catch (e) { /* Use default if controller disposed */ }

    for (final star in stars) {
      _starPaint.color = Colors.white.withOpacity(star.opacity * twinkleFactor);
      canvas.drawCircle(star.position, star.size, _starPaint);
    }

    // --- Draw Crescent Moon ---
    final moonRadius = size.width * 0.08;
    final moonCenter = Offset(size.width * 0.85, size.height * 0.15);
    final path = Path();
    path.addArc(Rect.fromCircle(center: moonCenter, radius: moonRadius), pi / 2, pi);
    path.arcTo(Rect.fromCircle(center: moonCenter.translate(moonRadius * 0.4, 0), radius: moonRadius * 0.8), pi * 1.5, -pi, false);
    path.close();
    canvas.drawPath(path, _moonPaint);


    // --- Draw Satellites ---
    try {
        // Check status instead of isDisposed
        if (satelliteController.status == AnimationStatus.dismissed) return; // Exit early if controller is gone

        final satelliteProgress = satelliteController.value;
        // Access duration safely only if not dismissed
        final totalSeconds = satelliteController.duration!.inSeconds;
        for (final satellite in satellites) {
          final satelliteDurationSeconds = satellite.duration.inSeconds;
          final startOffsetSeconds = satellite.startDelay.inSeconds;
          double currentSatelliteTime = (satelliteProgress * totalSeconds + startOffsetSeconds);
          double satelliteSpecificProgress = (currentSatelliteTime % satelliteDurationSeconds) / satelliteDurationSeconds;

          if (currentSatelliteTime < startOffsetSeconds) continue;

          final currentPos = Offset.lerp(satellite.startPos, satellite.endPos, satelliteSpecificProgress)!;
          _satellitePaint.color = Colors.blueGrey.shade200.withOpacity(0.9);
          canvas.drawRect(Rect.fromCenter(center: currentPos, width: satellite.size * 2, height: satellite.size), _satellitePaint);
          _satellitePaint.color = Colors.redAccent.withOpacity(0.9);
          if ((currentSatelliteTime * 2).floor() % 2 == 0) {
                canvas.drawCircle(currentPos.translate(satellite.size * 0.5, 0), satellite.size * 0.4, _satellitePaint);
          }
        }
    } catch (e) {
       // Error likely due to accessing disposed controller
       // print("Error painting satellites: $e");
    }

    // --- Draw Shooting Stars ---
    for (final star in shootingStars) {
       // Use try-catch for safety when accessing controller properties
       try {
         // Check status instead of isDisposed
         if (star.controller.status == AnimationStatus.dismissed) continue;

         final progress = star.controller.value;
         if (progress <= 0) continue;
         final headPos = Offset.lerp(star.startPos, star.endPos, progress)!;
         final tailProgress = (progress - 0.1).clamp(0.0, 1.0);
         final tailPos = Offset.lerp(star.startPos, star.endPos, tailProgress)!;
         final opacity = Curves.easeOutCubic.transform(min(progress * 5, 1.0)) *
                         (1.0 - Curves.easeInQuad.transform(progress));
         if (opacity <= 0) continue;
         _shootingStarPaint.color = star.color.withOpacity(opacity);
         _shootingStarPaint.strokeWidth = star.thickness * (1.0 - progress * 0.5);
         if ((headPos - tailPos).distanceSquared > 4) {
            canvas.drawLine(tailPos, headPos, _shootingStarPaint);
         } else {
            canvas.drawCircle(headPos, _shootingStarPaint.strokeWidth / 2, _shootingStarPaint);
         }
       } catch (e) {
         // print("Error painting shooting star (id ${star.id}): $e");
       }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
     // Let Listenable.merge handle repainting efficiently
     return false;
  }
}