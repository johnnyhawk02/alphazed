import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for rootBundle
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Needed for ui.Image
import '../services/audio_service.dart'; // Assuming AudioService path

// --- Helper Data Classes (Keep _Star, _Satellite, _ShootingStar, _Burst, _Particle as they are) ---

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
  bool _listenerAdded = false; // Track listener state

  _ShootingStar({
    required this.id,
    required this.startPos,
    required this.endPos,
    required this.controller,
    required this.onComplete,
    required this.color,
    required this.thickness,
  }) {
     _addStatusListenerOnce();
  }

  void _addStatusListenerOnce() {
    if (!_listenerAdded) {
      try {
        controller.addStatusListener(_statusListener);
        _listenerAdded = true;
      } catch (e) { /* Handle or log */ }
    }
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onComplete(id);
      _removeStatusListenerOnce();
    }
  }

  void _removeStatusListenerOnce() {
    if (_listenerAdded) {
      try {
        controller.removeStatusListener(_statusListener);
        _listenerAdded = false;
      } catch (e) { /* Ignore */ _listenerAdded = false; }
    }
  }
}

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

  void _addStatusListenerOnce(){
     if (!_listenerAdded) {
        try {
          controller.addStatusListener(_statusListener);
          _listenerAdded = true;
        } catch (e) {
          print("Error adding burst status listener: $e");
        }
     }
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onComplete(id);
       _removeStatusListenerOnce(); // Safely remove listener
    }
  }

   void _removeStatusListenerOnce() {
     if (_listenerAdded) {
       try {
         controller.removeStatusListener(_statusListener);
         _listenerAdded = false;
       } catch (e) {
         _listenerAdded = false; // Assume removed
       }
     }
   }

  void _generateParticles() {
    particles = List.generate(particleCount, (index) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * maxDistance;
      final particleColor = HSLColor.fromColor(baseColor)
          .withLightness((random.nextDouble() * 0.4) + 0.4) // Vary lightness
          .withSaturation((random.nextDouble() * 0.5) + 0.5) // Vary saturation
          .toColor();
      final lifetimeFactor = 0.8 + random.nextDouble() * 0.4;
      return _Particle(
        angle: angle, distance: distance, color: particleColor,
        size: 4.0 + random.nextDouble() * 6.0, // Vary size
        lifetimeFactor: lifetimeFactor
      );
    });
  }
}

class _Particle {
  final double angle; final double distance; final Color color; final double size; final double lifetimeFactor;
  _Particle({required this.angle, required this.distance, required this.color, required this.size, required this.lifetimeFactor });
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
  ui.Image? _moonImage;

  // Background Animation Controllers
  late AnimationController _satelliteController;
  late AnimationController _moonWiggleController;
  late Animation<double> _moonRotationAnimation;
  Timer? _shootingStarTimer;


  final List<String> _fireworkSounds = [
    'assets/audio/other/explosion.mp3',
    // Add more sound paths here
  ];

  // Image Loading Function
  Future<void> _loadMoonImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/pinata/moon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      if (mounted) { setState(() { _moonImage = fi.image; }); }
      else { fi.image.dispose(); }
    } catch (e) { print("Error loading moon image: $e"); }
  }

  @override
  void initState() {
    super.initState();

    _loadMoonImage();

    // --- Text Animation ---
    _textAnimationController = AnimationController( duration: const Duration(milliseconds: 1500), vsync: this, );
    _textScaleAnimation = TweenSequence<double>([ TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60), TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40), ]).animate(_textAnimationController);
    _textOpacityAnimation = TweenSequence<double>([ TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20), TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60), TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20), ]).animate(_textAnimationController);
    _textAnimationController.forward();

    // --- Completion Timer ---
    _completionTimer = Timer(const Duration(seconds: 10), () { if (mounted) widget.onComplete(); });

    // --- Initialize Background Elements ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
          final size = MediaQuery.of(context).size;
          _generateStars(size);
          _generateSatellites(size);
          if (mounted) setState(() {}); // Trigger rebuild after generation
      } catch (e) { print("Error during background initialization: $e"); }
    });

    // --- Satellite Animation ---
    _satelliteController = AnimationController( duration: const Duration(seconds: 60), vsync: this, )..repeat();

    // --- Moon Wiggle Animation (Gentle Rock) ---
    _moonWiggleController = AnimationController(
      duration: const Duration(seconds: 5), // Slower cycle
      vsync: this,
    )..repeat(reverse: true);
    _moonRotationAnimation = Tween<double>(
      begin: -0.015, // Reduced angle
      end: 0.015,   // Reduced angle
    ).animate(CurvedAnimation( parent: _moonWiggleController, curve: Curves.easeInOutSine, ));

    // --- Shooting Star Spawner ---
    _shootingStarTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
       if (mounted && _random.nextDouble() < 0.25) {
           try { if (mounted && context.findRenderObject()?.attached == true) { final size = MediaQuery.of(context).size; _addShootingStar(size); } }
           catch (e) { print("Error accessing context in shooting star timer: $e"); timer.cancel(); }
       }
    });

    // --- Initial Bursts ---
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         try { final size = MediaQuery.of(context).size; _addBurst(Offset(size.width / 2, size.height / 3)); Future.delayed(const Duration(milliseconds: 300), () { if(mounted) _addBurst(Offset(size.width * 0.3, size.height * 0.6)); }); Future.delayed(const Duration(milliseconds: 600), () { if(mounted) _addBurst(Offset(size.width * 0.7, size.height * 0.4)); }); }
         catch (e) { print("Error during initial burst setup: $e"); }
       }
     });
  }

  @override
  void dispose() {
    print("FireworksScreen disposing...");
    _completionTimer?.cancel();
    _shootingStarTimer?.cancel();

    try { _textAnimationController.dispose(); } catch (e) { /* ignore */ }
    try { _satelliteController.dispose(); } catch (e) { /* ignore */ }
    try { _moonWiggleController.dispose(); } catch (e) { /* ignore */ }

    _moonImage?.dispose();

    print("Disposing ${_bursts.length} burst controllers...");
    for (var burst in List.from(_bursts)) { try { burst.controller.dispose(); } catch (e) { /* ignore */ } }
    _bursts.clear();

    print("Disposing ${_shootingStars.length} shooting star controllers...");
    for (var star in List.from(_shootingStars)) { try { star.controller.dispose(); } catch (e) { /* ignore */ } }
    _shootingStars.clear();
    print("FireworksScreen dispose complete.");
    super.dispose();
  }

  // --- Background Element Generation (Keep _generateStars, _generateSatellites, _addShootingStar as they are) ---

 void _generateStars(Size size) {
    if (!mounted) return;
    _stars = List.generate(150, (index) { return _Star( position: Offset(_random.nextDouble() * size.width, _random.nextDouble() * size.height), size: _random.nextDouble() * 1.5 + 0.5, opacity: _random.nextDouble() * 0.5 + 0.3, ); });
  }

  void _generateSatellites(Size size) {
     if (!mounted) return;
     _satellites = [ _Satellite( startPos: Offset(-20, size.height * 0.2), endPos: Offset(size.width + 20, size.height * 0.4), size: 2.0, duration: const Duration(seconds: 70), startDelay: const Duration(seconds: 2) ), _Satellite( startPos: Offset(size.width * 0.3, -10), endPos: Offset(size.width * 0.3 + (_random.nextDouble() -0.5) * 50 , size.height + 10), size: 1.5, duration: const Duration(seconds: 50), startDelay: const Duration(seconds: 5) ), _Satellite( startPos: Offset(size.width + 15, size.height * 0.8), endPos: Offset(-15, size.height * 0.1), size: 2.5, duration: const Duration(seconds: 60), startDelay: Duration.zero ), ];
  }

  void _addShootingStar(Size size) {
      if (!mounted) return;
      final bool fromTop = _random.nextBool(); final bool fromLeft = _random.nextBool(); double startX, startY, endX, endY; const margin = 50.0;
      if (fromTop) { startY = -margin; endY = size.height * (_random.nextDouble() * 0.5 + 0.3); startX = _random.nextDouble() * size.width; endX = fromLeft ? startX - (size.width * 0.5 + _random.nextDouble() * size.width * 0.5) : startX + (size.width * 0.5 + _random.nextDouble() * size.width * 0.5); }
      else { startY = size.height + margin; endY = size.height * (_random.nextDouble() * 0.5); startX = _random.nextDouble() * size.width; endX = fromLeft ? startX - (size.width * 0.5 + _random.nextDouble() * size.width * 0.5) : startX + (size.width * 0.5 + _random.nextDouble() * size.width * 0.5); }
      if ((startX - endX).abs() < size.width * 0.3) { endX = fromLeft ? startX - size.width * 0.5 : startX + size.width * 0.5; }
      AnimationController? controller;
      try { if (!mounted) return; controller = AnimationController( duration: Duration(milliseconds: 600 + _random.nextInt(600)), vsync: this, ); final star = _ShootingStar( id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000), startPos: Offset(startX, startY), endPos: Offset(endX, endY), controller: controller, color: Colors.white.withOpacity(0.8), thickness: _random.nextDouble() * 1.5 + 1.0, onComplete: (id) { if (mounted) { setState(() { _shootingStars.removeWhere((s) => s.id == id); }); } }, ); if (mounted) { setState(() { _shootingStars.add(star); }); controller.forward(); } else { controller.dispose(); } }
      catch (e) { print("Error creating/starting shooting star animation: $e"); controller?.dispose(); }
   }

  // --- Event Handlers & Burst Logic (Keep _handleTap, _playRandomFireworkSound, _addBurst as they are) ---

  void _handleTap(TapDownDetails details) { if (!mounted) return; _addBurst(details.localPosition); _playRandomFireworkSound(); }
  void _playRandomFireworkSound() { if (!mounted || _fireworkSounds.isEmpty) return; try { final soundPath = _fireworkSounds[_random.nextInt(_fireworkSounds.length)]; widget.audioService.playShortSoundEffect(soundPath, stopPreviousEffect: false); } catch(e) { print("Error playing firework sound: $e"); } }
  void _addBurst(Offset position) { if (!mounted) return; AnimationController? controller; try { if (!mounted) return; controller = AnimationController( duration: const Duration(milliseconds: 1200), vsync: this, ); final burst = _Burst( id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000), position: position, controller: controller, particleCount: 40 + _random.nextInt(40), maxDistance: 80 + _random.nextDouble() * 80, baseColor: Colors.primaries[_random.nextInt(Colors.primaries.length)], random: _random, onComplete: (id) { if (mounted) { setState(() { _bursts.removeWhere((b) => b.id == id); }); } }, ); if (mounted) { setState(() { _bursts.add(burst); }); controller.forward(); } else { controller.dispose(); } } catch (e) { print("Error creating/starting burst animation: $e"); controller?.dispose(); } }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black, // REMOVED - Background image will cover this
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // --- Background Image Layer --- <--- NEW
            Positioned.fill( // Ensures the image fills the stack
              child: Image.asset(
                'assets/images/pinata/night_sky.png',
                fit: BoxFit.cover, // Cover the whole screen, cropping if necessary
              ),
            ),

            // --- Background Elements Layer (Stars, Moon, Satellites, Shooting Stars) ---
            CustomPaint(
              painter: _BackgroundPainter(
                stars: _stars,
                satellites: _satellites,
                shootingStars: List.from(_shootingStars),
                satelliteController: _satelliteController,
                moonImage: _moonImage,
                moonRotationAnimation: _moonRotationAnimation,
              ),
              size: Size.infinite,
            ),

            // --- Particle Bursts Layer ---
            if (_bursts.isNotEmpty)
              CustomPaint(
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
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 15.0,
                          color: Colors.orangeAccent,
                        ),
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 4.0,
                          color: Colors.black87,
                        ),
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
} // End of _FireworksScreenState


// --- Fireworks Painter (_FireworksPainter - Keep as is) ---
class _FireworksPainter extends CustomPainter {
  final List<_Burst> bursts;
  final Paint _paint = Paint();
   _FireworksPainter({required this.bursts}) : super(repaint: Listenable.merge( bursts.map((b) => b.controller).toList() ));

  @override void paint(Canvas canvas, Size size) {
     if (bursts.isEmpty) return;
     for (final burst in bursts) {
        try { if (burst.controller.status == AnimationStatus.dismissed) continue; final progress = burst.controller.value; for (final particle in burst.particles) { final curveProgress = Curves.easeOutCubic.transform(progress); final currentDistance = particle.distance * curveProgress; final dx = burst.position.dx + cos(particle.angle) * currentDistance; final gravityEffect = pow(progress, 2) * 150 * particle.lifetimeFactor; final dy = burst.position.dy + sin(particle.angle) * currentDistance + gravityEffect; final currentPos = Offset(dx, dy); final opacity = max(0.0, (1.0 - (progress * 1.5 / particle.lifetimeFactor)).clamp(0.0, 1.0)); if (opacity <= 0) continue; _paint.color = particle.color.withOpacity(opacity); canvas.drawCircle(currentPos, particle.size * (1.0 - progress * 0.5), _paint); } }
        catch (e) { /* ignore */ }
     }
  }
  @override bool shouldRepaint(covariant _FireworksPainter oldDelegate) { return bursts.length != oldDelegate.bursts.length || bursts.any((b) => b.controller.isAnimating); }
}


// --- Background Painter (_BackgroundPainter - Keep as is) ---
// Draws stars, moon (image), satellites, and shooting stars
class _BackgroundPainter extends CustomPainter {
  final List<_Star> stars; final List<_Satellite> satellites; final List<_ShootingStar> shootingStars; final AnimationController satelliteController; final ui.Image? moonImage; final Animation<double> moonRotationAnimation;
  _BackgroundPainter({ required this.stars, required this.satellites, required this.shootingStars, required this.satelliteController, required this.moonImage, required this.moonRotationAnimation, }) : super(repaint: Listenable.merge([ satelliteController, moonRotationAnimation, ...shootingStars.map((s) => s.controller) ]));
  final Paint _starPaint = Paint(); final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium; final Paint _satellitePaint = Paint()..color = Colors.blueGrey.shade200.withOpacity(0.9); final Paint _shootingStarPaint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw Stars ---
    double twinkleFactor = 0.75; try { if (satelliteController.status != AnimationStatus.dismissed) { twinkleFactor = (0.5 + (sin(satelliteController.value * 2 * pi * 2) + 1) / 4); } } catch (e) { /* ignore */ }
    for (final star in stars) { _starPaint.color = Colors.white.withOpacity(star.opacity * twinkleFactor); canvas.drawCircle(star.position, star.size, _starPaint); }

    // --- Draw Crescent Moon (with Wiggle) ---
    if (moonImage != null) { final img = moonImage!; final double moonWidth = size.width * 0.18; final double moonHeight = (img.height / img.width) * moonWidth; final Offset moonCenter = Offset(size.width * 0.85, size.height * 0.15); final Rect dstRect = Rect.fromCenter( center: Offset.zero, width: moonWidth, height: moonHeight ); final Rect srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()); canvas.save(); canvas.translate(moonCenter.dx, moonCenter.dy); try { canvas.rotate(moonRotationAnimation.value); } catch (e) { /* ignore rotation if error */ } canvas.drawImageRect(img, srcRect, dstRect, _imagePaint); canvas.restore(); }
    else { /* Optional Fallback Drawing */ }

    // --- Draw Satellites ---
    try { if (satelliteController.status == AnimationStatus.dismissed) return; final satelliteProgress = satelliteController.value; final totalSeconds = satelliteController.duration!.inSeconds; for (final satellite in satellites) { final satelliteDurationSeconds = satellite.duration.inSeconds; final startOffsetSeconds = satellite.startDelay.inSeconds; double currentSatelliteTime = (satelliteProgress * totalSeconds + startOffsetSeconds); double satelliteSpecificProgress = (currentSatelliteTime % satelliteDurationSeconds) / satelliteDurationSeconds; if (currentSatelliteTime < startOffsetSeconds) continue; final currentPos = Offset.lerp(satellite.startPos, satellite.endPos, satelliteSpecificProgress)!; _satellitePaint.color = Colors.blueGrey.shade200.withOpacity(0.9); canvas.drawRect(Rect.fromCenter(center: currentPos, width: satellite.size * 2, height: satellite.size), _satellitePaint); _satellitePaint.color = Colors.redAccent.withOpacity(0.9); if ((currentSatelliteTime * 2).floor() % 2 == 0) { canvas.drawCircle(currentPos.translate(satellite.size * 0.5, 0), satellite.size * 0.4, _satellitePaint); } } }
    catch (e) { /* ignore */ }

    // --- Draw Shooting Stars ---
    for (final star in shootingStars) { try { if (star.controller.status == AnimationStatus.dismissed) continue; final progress = star.controller.value; if (progress <= 0) continue; final headPos = Offset.lerp(star.startPos, star.endPos, progress)!; final tailProgress = (progress - 0.1).clamp(0.0, 1.0); final tailPos = Offset.lerp(star.startPos, star.endPos, tailProgress)!; final opacity = Curves.easeOutCubic.transform(min(progress * 5, 1.0)) * (1.0 - Curves.easeInQuad.transform(progress)); if (opacity <= 0) continue; _shootingStarPaint.color = star.color.withOpacity(opacity); _shootingStarPaint.strokeWidth = star.thickness * (1.0 - progress * 0.5); if ((headPos - tailPos).distanceSquared > 4) { canvas.drawLine(tailPos, headPos, _shootingStarPaint); } else { canvas.drawCircle(headPos, _shootingStarPaint.strokeWidth / 2, _shootingStarPaint); } }
      catch (e) { /* ignore */ } }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) { return oldDelegate.moonImage != moonImage; }
} // End of _BackgroundPainter