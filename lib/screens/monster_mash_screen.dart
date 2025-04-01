import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle and ui.Image
import 'package:vector_math/vector_math_64.dart' show Vector2; // For physics
import 'package:confetti/confetti.dart'; // For popping effect

import '../services/audio_service.dart';

// --- Configuration ---
const int _monsterCount = 6; // Number of monsters to pop
// Monster size is now relative to screen width, so these are less critical
// const double _minMonsterSize = 70.0;
// const double _maxMonsterSize = 110.0;
const double _gravity = 60.0; // Slightly higher gravity
const double _damping = 0.60; // A bit more energy loss
const double _maxSpeed = 550.0; // Slightly slower max speed for easier tapping
const double _initialUpwardBoost = -150.0; // Give them a little starting jump
const double _collisionRestitution = 0.6; // How much energy is kept after monster-monster collision (0-1)
const double _collisionRotationFactor = 0.05; // How much collisions affect rotation

// --- Helper Class for Enhanced Monster State ---
class _Monster {
  final int id;
  final ui.Image image;
  final Size size;
  Vector2 position;
  Vector2 velocity;
  double rotation;
  double rotationVelocity;

  bool isPopped = false; // Has this monster been tapped?
  bool isGone = false; // Has the fly-off animation completed?

  // Animation Controllers
  final AnimationController popController; // Controls squash/pop animation
  final AnimationController flyOffController; // Controls flying off screen
  final ConfettiController confettiController; // For particle burst on pop

  // Animations
  late Animation<double> squashScaleX;
  late Animation<double> squashScaleY;
  late Animation<double> popRotation;
  late Animation<Offset> flyOffPosition;
  late Animation<double> flyOffScale;
  late Animation<double> flyOffRotation;


  _Monster({
    required this.id,
    required this.image,
    required this.size,
    required this.position,
    required this.velocity,
    required TickerProvider vsync,
    required VoidCallback onGone, // Callback when fly-off completes
    this.rotation = 0.0,
    this.rotationVelocity = 0.0,
  }) : popController = AnimationController(
          vsync: vsync, duration: const Duration(milliseconds: 350)),
       flyOffController = AnimationController(
          vsync: vsync, duration: const Duration(milliseconds: 600)),
       confettiController = ConfettiController(
          duration: const Duration(milliseconds: 400)) // Short burst
  {
     // Squash Animation (Y squashes, X expands slightly, then snaps back)
    squashScaleY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 40), // Squash down
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.2), weight: 30), // Overshoot Y
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30), // Settle Y
    ]).animate(CurvedAnimation(parent: popController, curve: Curves.elasticOut));

    squashScaleX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40), // Expand X
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30), // Undershoot X
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30), // Settle X
    ]).animate(CurvedAnimation(parent: popController, curve: Curves.elasticOut));

    // Quick jiggle rotation during pop
    popRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: popController, curve: Curves.easeInOut));

    // Fly Off Animation setup (initialized later when pop happens)
    flyOffPosition = ConstantTween<Offset>(Offset.zero).animate(flyOffController);
    flyOffScale = ConstantTween<double>(1.0).animate(flyOffController);
    flyOffRotation = ConstantTween<double>(0.0).animate(flyOffController);

    // Listener to mark as gone after fly-off
    flyOffController.addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         isGone = true;
         onGone(); // Notify the main screen state
       }
     });
  }

  // Method to trigger the popping sequence
  void pop(Offset screenSizeOffset, math.Random random) {
    if (isPopped) return;
    isPopped = true;
    popController.forward(from: 0.0);
    confettiController.play(); // Play particle burst

    // Setup fly-off animation relative to pop location
    final endPos = Offset(
        (random.nextDouble() - 0.5) * screenSizeOffset.dx * 1.5, // Fly off screen L/R
        -screenSizeOffset.dy * 0.6); // Fly upwards off screen
    final endRotation = (random.nextDouble() - 0.5) * math.pi * 4; // Spin wildly

    flyOffPosition = Tween<Offset>(begin: Offset.zero, end: endPos)
      .animate(CurvedAnimation(parent: flyOffController, curve: Curves.easeOut));
    flyOffScale = Tween<double>(begin: 1.0, end: 0.1) // Shrink as it flies
      .animate(CurvedAnimation(parent: flyOffController, curve: Curves.easeIn));
    flyOffRotation = Tween<double>(begin: rotation, end: rotation + endRotation)
        .animate(CurvedAnimation(parent: flyOffController, curve: Curves.linear)); // Linear spin

    // Start fly-off after pop animation roughly completes
    Future.delayed(popController.duration! * 0.8, () {
      if (!isGone && popController.status != AnimationStatus.dismissed) { // Ensure pop animation wasn't interrupted/disposed
         flyOffController.forward(from: 0.0);
      }
    });
  }


  bool contains(Offset point) {
     if (isPopped || isGone) return false; // Cannot tap popped or gone monster
    // Use current position for tap check
    final rect = Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.width * 1.1, // Slightly larger tap target
        height: size.height * 1.1);
    return rect.contains(point);
  }

  void dispose() {
    popController.dispose();
    flyOffController.dispose();
    confettiController.dispose();
    image.dispose();
  }
}

// --- Main Screen Widget ---
class MonsterMashScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onComplete;

  const MonsterMashScreen({
    Key? key,
    required this.audioService,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MonsterMashScreen> createState() => _MonsterMashScreenState();
}

class _MonsterMashScreenState extends State<MonsterMashScreen>
    with TickerProviderStateMixin {
  final List<_Monster> _monsters = [];
  final math.Random _random = math.Random();
  bool _showNextButton = false;
  bool _isLoading = true;
  String? _loadingError;
  int _poppedCount = 0; // Track popped monsters
  int _goneCount = 0; // Track monsters that finished flying off

  late AnimationController _loopController;
  DateTime _lastUpdateTime = DateTime.now();

  ui.Image? _backgroundImage;
  final String _backgroundPath = 'assets/images/pinata/pinata_courtyard.png'; // Friendlier background?
  final String _popSoundPath = 'assets/audio/other/plop.mp3'; // Placeholder - find a good "pop" or "squish"

  @override
  void initState() {
    super.initState();
    _startLoading();

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration doesn't really matter
    )..repeat();

    _loopController.addListener(_updatePhysics);
     _lastUpdateTime = DateTime.now();
  }

  Future<void> _startLoading() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadingError = null; });
    try {
      _backgroundImage = await _loadUiImage(_backgroundPath);
      final List<ui.Image> loadedImages = [];
      final List<String> monsterLoadErrors = [];
      for (int i = 1; i <= 6; i++) {
        String monsterNumber = i.toString().padLeft(2, '0');
        String assetPath = 'assets/images/pinata/monster$monsterNumber.png';
        try {
          loadedImages.add(await _loadUiImage(assetPath));
          print("Loaded: $assetPath");
        } catch (e) {
          print("Warning: Could not load $assetPath - $e");
          monsterLoadErrors.add(assetPath);
        }
      }
      if (loadedImages.isEmpty) { throw Exception("Failed to load any monster images (monster01-monster06). Check assets/images/pinata/ folder."); }
      if (monsterLoadErrors.isNotEmpty) { print("Warning: Missing monster images: ${monsterLoadErrors.join(', ')}"); }

      // Ensure the first frame is built before accessing MediaQuery
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final Size screenSize = MediaQuery.of(context).size;
        if (screenSize.isEmpty) { // Handle case where size might be zero initially
            print("Warning: Screen size is zero during monster initialization.");
            // Optionally wait and retry, or use default dimensions
            return;
        }
        _initializeMonsters(loadedImages, screenSize);
        if (mounted) { setState(() { _isLoading = false; }); }
      });
    } catch (e) {
      print("Error loading assets for MonsterMashScreen: $e");
      if (mounted) { setState(() { _isLoading = false; _loadingError = "Failed to load monsters: $e"; }); }
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  // --- UPDATED _initializeMonsters ---
  void _initializeMonsters(List<ui.Image> images, Size screenSize) {
    _monsters.clear();
    _poppedCount = 0; // Reset counts
    _goneCount = 0;
    final int countToCreate = math.min(images.length, _monsterCount);

    // Calculate target width based on screen size
    final double targetMonsterWidth = screenSize.width / 3.0; // 1/3rd of screen width

    for (int i = 0; i < countToCreate; i++) {
      final image = images[i];

      // Calculate size based on target width and aspect ratio
      final double aspectRatio = (image.height > 0) ? image.width.toDouble() / image.height.toDouble() : 1.0;
      // Ensure height isn't zero if aspectRatio resulted in it
      final double monsterHeight = (targetMonsterWidth / aspectRatio).clamp(1.0, screenSize.height); // Ensure height > 0
      final Size monsterSize = Size(targetMonsterWidth, monsterHeight);

      // Ensure initial position is within bounds, considering the new fixed width
      // Clamp initial values just in case calculation yields negative or out-of-bounds results
      final initialX = (monsterSize.width / 2 + _random.nextDouble() * (screenSize.width - monsterSize.width)).clamp(monsterSize.width/2, screenSize.width - monsterSize.width/2);
      // Start higher up, ensure valid Y pos
      final initialY = (monsterSize.height / 2 + _random.nextDouble() * (screenSize.height * 0.66 - monsterSize.height)).clamp(monsterSize.height/2, screenSize.height * 0.75); // Adjust clamp as needed

      _monsters.add(_Monster(
        id: i,
        image: image,
        size: monsterSize, // Use the calculated size
        position: Vector2(initialX, initialY),
        velocity: Vector2(
          _random.nextDouble() * 100 - 50, // Less X velocity initially
          _initialUpwardBoost + _random.nextDouble() * 50 // Y boost
        ),
        rotation: _random.nextDouble() * math.pi * 0.2 - 0.1, // Less rotation
        rotationVelocity: _random.nextDouble() * 0.5 - 0.25, // Slower spin
        vsync: this,
        onGone: () {
            _handleMonsterGone(); // Pass the callback
        }
      ));
    }
  }
  // --- END UPDATED _initializeMonsters ---


  void _handleMonsterGone() {
    if (!mounted) return;
    _goneCount++;
    print("Monster gone: $_goneCount / ${_monsters.length}");
    // Check if all *originally initialized* monsters are gone
    if (_goneCount >= _monsters.length && _monsters.isNotEmpty) {
       print("All monsters are gone!");
       // Prevent setting state if button already shown or game ended
       if (!_showNextButton) {
           setState(() { _showNextButton = true; });
       }
    }
  }

  @override
  void dispose() {
    print("Disposing MonsterMashScreen...");
    _loopController.removeListener(_updatePhysics);
    _loopController.dispose();
    for (var monster in _monsters) {
      monster.dispose();
    }
    _backgroundImage?.dispose();
    print("MonsterMashScreen disposed.");
    super.dispose();
  }

  void _updatePhysics() {
    if (!mounted || _monsters.isEmpty || _isLoading) return; // Added _isLoading check
    final now = DateTime.now();
    final double dt = (now.difference(_lastUpdateTime).inMicroseconds / 1000000.0).clamp(0.0, 0.032);
    _lastUpdateTime = now;
    if (dt <= 0) return;
    final Size screenSize = MediaQuery.of(context).size;

    // 1. Apply forces and update position/rotation for each monster
    for (final monster in _monsters) {
      if (!monster.isPopped) { // Only apply physics to monsters that haven't been popped
          monster.velocity.y += _gravity * dt;
          // Air resistance
          double dragFactor = math.pow(0.98, dt * 60).toDouble(); // dt*60 scales resistance similar to 60fps
          monster.velocity.scale(dragFactor);
          monster.rotationVelocity *= math.pow(0.97, dt*60).toDouble(); // Rotational drag

          if (monster.velocity.length > _maxSpeed) {
              monster.velocity.normalize();
              monster.velocity.scale(_maxSpeed);
          }

          monster.position += monster.velocity * dt;
          monster.rotation += monster.rotationVelocity * dt;

          // Boundary collisions
          final halfW = monster.size.width / 2; final halfH = monster.size.height / 2;
          bool hitWall = false;
          bool hitFloor = false;

          if (monster.position.x <= halfW) { monster.position.x = halfW; monster.velocity.x *= -_damping; hitWall = true; }
          else if (monster.position.x >= screenSize.width - halfW) { monster.position.x = screenSize.width - halfW; monster.velocity.x *= -_damping; hitWall = true;}

          if (hitWall) {
              monster.rotationVelocity *= -_damping * 0.5; // Weaker rotation bounce on side walls
          }

          // Allow bouncing slightly above floor before full stop?
          double floorLevel = screenSize.height - halfH;
          if (monster.position.y >= floorLevel) {
            monster.position.y = floorLevel;
             // Dampen vertical velocity significantly on floor hit
             if (monster.velocity.y > 0) { // Only apply damping if moving downwards
                 monster.velocity.y *= -_damping * 0.8; // Stronger Y damping on floor
             }
             // Apply friction to horizontal movement and rotation on floor
             monster.velocity.x *= 0.95;
             monster.rotationVelocity *= 0.9;
             hitFloor = true;

              // Kill very small vertical bounces to prevent jittering
             if(monster.velocity.y.abs() < 5.0) {
                monster.velocity.y = 0;
             }
          }
           // Top boundary (less critical, mainly prevents escaping)
           else if (monster.position.y < halfH) { monster.position.y = halfH; if(monster.velocity.y < 0) monster.velocity.y *= -_damping; }

      }
      // No physics update if monster.isPopped
    }

    // 2. Monster-to-Monster Collision Detection and Response
    for (int i = 0; i < _monsters.length; i++) {
      final monsterA = _monsters[i];
      if (monsterA.isPopped || monsterA.isGone) continue;

      for (int j = i + 1; j < _monsters.length; j++) {
        final monsterB = _monsters[j];
        if (monsterB.isPopped || monsterB.isGone) continue;

        final Vector2 diff = monsterB.position - monsterA.position;
        final double distance = diff.length;
        // Use average width as radius, maybe slightly smaller for better feel
        final double radiusA = monsterA.size.width * 0.4;
        final double radiusB = monsterB.size.width * 0.4;
        final double minDistance = radiusA + radiusB;

        if (distance < minDistance && distance > 0.01) { // Collision detected (and not exactly same spot)
          // Resolve Overlap
          final Vector2 normal = diff.normalized();
          final double overlap = minDistance - distance;
          // Move them apart slightly (can be improved with mass consideration)
          monsterA.position -= normal * (overlap / 2.0);
          monsterB.position += normal * (overlap / 2.0);

          // Collision Response (Simplified Elastic Collision)
          final Vector2 relativeVelocity = monsterB.velocity - monsterA.velocity;
          final double velocityAlongNormal = relativeVelocity.dot(normal);

          // Only apply response if they are moving towards each other
          if (velocityAlongNormal < 0) {
            final double impulseMagnitude = -(1 + _collisionRestitution) * velocityAlongNormal;
            // Assuming equal mass for simplicity
            final Vector2 impulse = normal * (impulseMagnitude / 2.0);

            monsterA.velocity -= impulse;
            monsterB.velocity += impulse;

            // Add some rotation based on collision
            // Simplified: Add a small random spin or based on tangential component
            final Vector2 tangent = Vector2(-normal.y, normal.x);
            final double tangentialVelA = monsterA.velocity.dot(tangent);
            final double tangentialVelB = monsterB.velocity.dot(tangent);
            monsterA.rotationVelocity += (tangentialVelB - tangentialVelA) * _collisionRotationFactor * (_random.nextDouble() - 0.5);
            monsterB.rotationVelocity -= (tangentialVelA - tangentialVelB) * _collisionRotationFactor * (_random.nextDouble() - 0.5);
          }
        }
      }
    }
  }

  void _handleTap(TapDownDetails details) {
    if (_isLoading || _monsters.isEmpty || _showNextButton) return; // Prevent taps if loading or done
    final tapPosition = details.localPosition;

    // Iterate in reverse to tap the topmost monster visually
    for (int i = _monsters.length - 1; i >= 0; i--) {
      final monster = _monsters[i];
      // Check contains() which handles !isPopped and !isGone
      if (monster.contains(tapPosition)) {
        print("Popping monster ${monster.id}");

        monster.pop(Offset(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height), _random);

        widget.audioService.playShortSoundEffect(_popSoundPath, stopPreviousEffect: false);

        setState(() { _poppedCount++; });

        // Check if all popped - trigger earlier maybe? (No, wait for gone)
        // if (_poppedCount >= _monsters.length) { }

        break; // Pop only one
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback background
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque, // Capture taps anywhere on the Stack
        child: Stack(
          children: [
            // Background Layer
            if (_backgroundImage != null)
               Positioned.fill(child: CustomPaint(painter: _BackgroundPainter(_backgroundImage!))),

            // Loading / Error Layer
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_loadingError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text( _loadingError!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center ),
                ),
              ),

            // Main content area for Monsters and Confetti
            if (!_isLoading && _loadingError == null)
              Positioned.fill(
                child: CustomPaint(
                  // Painter draws monsters based on their state (physics or flyoff)
                  painter: _MonsterPainter(monsters: _monsters, repaint: _loopController),
                  // Child stack for placing confetti widgets logically "near" the monsters
                  child: Stack(
                    children: _monsters.map((monster) {
                       // Confetti should align with the monster's *current* position
                       return Positioned(
                           left: monster.position.x - monster.size.width, // Adjust offset for desired explosion origin
                           top: monster.position.y - monster.size.height, // centered around monster center maybe?
                           width: monster.size.width * 2, // Area for confetti source
                           height: monster.size.height * 2,
                           child: Align( // Use Align within Positioned to center confetti source if needed
                              alignment: Alignment.center,
                              child: ConfettiWidget(
                                confettiController: monster.confettiController,
                                blastDirectionality: BlastDirectionality.explosive,
                                particleDrag: 0.05,
                                emissionFrequency: 0.0, // Emit all at once
                                numberOfParticles: 25,
                                gravity: 0.3,
                                shouldLoop: false,
                                colors: const [Colors.greenAccent, Colors.limeAccent, Colors.yellowAccent, Colors.white], // Goo/burst colors
                              ),
                           )
                        );
                    }).toList(),
                  ),
                ),
              ),

             // Remaining Monsters Counter UI
             if (!_isLoading && _loadingError == null && !_showNextButton) // Hide counter when done
             Positioned(
                top: MediaQuery.of(context).padding.top + 10, // Adjust for status bar
                right: 20,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Text(
                        'Pop!: ${_monsters.length - _poppedCount}', // Show remaining count
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                )
             ),

            // NEXT WORD Button - shows when all monsters are GONE
            if (_showNextButton)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                       print("Next Word button tapped");
                       widget.onComplete(); // Call the callback to proceed
                    },
                    child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                       decoration: BoxDecoration(
                          color: Colors.green.shade600, // Success color
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.5), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5), ),],
                          border: Border.all( color: Colors.white.withOpacity(0.7), width: 2)
                       ),
                       child: const Text( 'NEXT WORD', style: TextStyle( fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5, shadows: [ Shadow( offset: Offset(1.0, 1.0), blurRadius: 2.0, color: Colors.black45, ),]),
                       ),
                    ),
                  ),
                ),
              ),

            // Back Button (Always available for early exit)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10, // Adjust for status bar
              left: 20,
              child: Container(
                  decoration: BoxDecoration( color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, ),
                  // Ensure button is tappable even if monsters are underneath
                  child: Material( // Use Material for ink splash effect on tap
                     color: Colors.transparent,
                     shape: const CircleBorder(),
                     child: InkWell(
                       customBorder: const CircleBorder(),
                       onTap: () {
                         print("Back button tapped");
                         widget.onComplete(); // Allow early exit
                       },
                       child: const Padding(
                         padding: EdgeInsets.all(8.0), // Add padding inside InkWell
                         child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                       ),
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

// --- Custom Painter for Monsters (Handles Pop/FlyOff states) ---
class _MonsterPainter extends CustomPainter {
  final List<_Monster> monsters;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium; // Medium for performance/quality balance

  _MonsterPainter({required this.monsters, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final monster in monsters) {
        // Skip drawing if the monster has finished flying off
        if (monster.isGone) continue;

      canvas.save();

      // Apply transformations based on state
      if (monster.isPopped && !monster.isGone) { // Popped and flying off
          // Apply fly-off translation (relative to the canvas origin, not current pos)
          canvas.translate(monster.flyOffPosition.value.dx, monster.flyOffPosition.value.dy);
          // Move to the monster's last known physical position before pop (for fly-off origin)
          canvas.translate(monster.position.x, monster.position.y);
          // Apply fly-off rotation and scale
          canvas.rotate(monster.flyOffRotation.value);
          canvas.scale(monster.flyOffScale.value);
          // Do NOT apply pop scale/rotation during fly-off - let flyOffScale handle shrinking
      } else if (monster.popController.isAnimating) { // Popping animation active
          canvas.translate(monster.position.x, monster.position.y);
          // Base rotation applied first
          canvas.rotate(monster.rotation);
           // Pop animations applied on top
          canvas.rotate(monster.popRotation.value * math.pi);
          canvas.scale(monster.squashScaleX.value, monster.squashScaleY.value);
      }
      else { // Normal physics state
          canvas.translate(monster.position.x, monster.position.y);
          canvas.rotate(monster.rotation);
      }

      // Draw the monster image, centered around the final transformed origin
      final srcRect = Rect.fromLTWH(0, 0, monster.image.width.toDouble(), monster.image.height.toDouble());
      final dstRect = Rect.fromCenter(
          center: Offset.zero, // Draw at (0,0) of the transformed canvas
          width: monster.size.width,
          height: monster.size.height
      );
      canvas.drawImageRect(monster.image, srcRect, dstRect, _paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MonsterPainter oldDelegate) {
    // Repainting is primarily driven by the Listenable.
    // This provides a fallback repaint trigger if the list itself changes.
    return monsters.length != oldDelegate.monsters.length;
  }
}


// --- Custom Painter for Background Image (No Changes) ---
class _BackgroundPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low; // Low quality okay for background

  _BackgroundPainter(this.backgroundImage);

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Could use BoxFit.cover logic here if needed
    canvas.drawImageRect(backgroundImage, srcRect, dstRect, _paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return backgroundImage != oldDelegate.backgroundImage; // Only repaint if image changes
  }
}