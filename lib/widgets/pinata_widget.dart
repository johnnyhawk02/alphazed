import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import '../services/audio_service.dart'; // Ensure this path is correct

class PinataWidget extends StatefulWidget {
  final double width;
  final double height;
  final String intactImagePath;
  final String brokenImagePath;
  final Function() onBroken; // Callback when breaking starts
  final Function()? onCompletelyGone; // Callback for when fly-off is complete
  final int requiredTaps;
  final AudioService audioService;
  final Function()? onTap; // Added callback for parent to track taps

  const PinataWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.intactImagePath,
    required this.brokenImagePath,
    required this.onBroken,
    required this.audioService,
    this.onCompletelyGone,
    this.onTap,
    this.requiredTaps = 3,
  }) : super(key: key);

  @override
  State<PinataWidget> createState() => _PinataWidgetState();
}

class _PinataWidgetState extends State<PinataWidget> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _wobbleController;
  late AnimationController _flyOffController;
  late AnimationController _driftController;

  // Animations
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _driftAnimation;

  // State Variables
  bool _isBroken = false;
  int _tapCount = 0;
  bool _isFlyingOff = false;
  bool _isCompletelyGone = false;

  // Configuration
  Offset _flyOffDirection = Offset.zero;
  final double _initialScale = 1.3; // Initial larger size

  // Confetti Controllers
  late ConfettiController _sparkController; // Main explosion
  final List<ConfettiController> _sparkControllers = []; // Tap sparks

  // Utilities
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // --- Wobble Animation Setup ---
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _setupRotationAnimation();
    _wobbleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isBroken && !_isFlyingOff) {
          _wobbleController.reverse();
      }
    });

    // --- Fly-Off Animation Setup ---
    _flyOffController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: _initialScale, end: _initialScale).animate(_flyOffController);
    _positionAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_flyOffController);
     _flyOffController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() { _isCompletelyGone = true; });
            widget.onCompletelyGone?.call();
          }
        }
     });

    // --- Confetti Setup ---
    _sparkController = ConfettiController(duration: const Duration(milliseconds: 2500));
    for (int i = 0; i < 5; i++) {
      _sparkControllers.add(ConfettiController(duration: const Duration(milliseconds: 300)));
    }

    // --- Drift Animation Setup ---
    _driftController = AnimationController(
      duration: Duration(milliseconds: 3000 + _random.nextInt(2000)),
      vsync: this,
    );
    _setupDriftAnimation();
    if (!_isBroken) {
        _driftController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _flyOffController.dispose();
    _driftController.dispose();
    _sparkController.dispose();
    for (var controller in _sparkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Animation Setup Helpers ---

  void _setupRotationAnimation() {
    final direction = _random.nextBool() ? 1.0 : -1.0;
    final intensity = 0.05 + (_random.nextDouble() * 0.15);
    _rotationAnimation = Tween<double>(
      begin: direction * intensity * -1,
      end: direction * intensity,
    ).animate(CurvedAnimation(parent: _wobbleController, curve: Curves.elasticInOut));
  }

  void _setupDriftAnimation() {
    final driftAmount = 0.03 + (_random.nextDouble() * 0.04);
    _driftAnimation = Tween<double>(
      begin: -driftAmount, end: driftAmount,
    ).animate(CurvedAnimation(parent: _driftController, curve: Curves.easeInOut));
  }

  void _setupFlyOffAnimation() {
    final angle = _random.nextDouble() * 2 * math.pi;
    _flyOffDirection = Offset(math.cos(angle), math.sin(angle));
    _scaleAnimation = Tween<double>(begin: _initialScale, end: 0.0)
        .animate(CurvedAnimation(parent: _flyOffController, curve: Curves.easeIn));
    _positionAnimation = Tween<Offset>(begin: Offset.zero, end: _flyOffDirection * 15.0)
        .animate(CurvedAnimation(parent: _flyOffController, curve: Curves.easeOutExpo));
  }

  // --- Sound Playback Helpers (using updated AudioService) ---

  void _playTapSound() {
     widget.audioService.playPinataTap();
  }

  void _playBreakSound() {
     widget.audioService.playPinataBreak();
  }

  // --- Main Interaction Logic ---

  // Make async only for the delayed fly-off, not for sound timing
  void _handleTap() {
    if (_isBroken || _isFlyingOff || _isCompletelyGone) return;

    setState(() { _tapCount++; });

    // Play tap sound for EVERY tap using the dedicated effect method
    _playTapSound();

    // Show tap spark effect
    final index = _random.nextInt(_sparkControllers.length);
    _sparkControllers[index].play();

    // Trigger wobble animation
    _setupRotationAnimation();
    _wobbleController.forward(from: 0.0);

    // Check for final tap
    if (_tapCount >= widget.requiredTaps) {
      if (mounted) { setState(() { _isBroken = true; }); }
      widget.onBroken();
      _driftController.stop();

      // Play explosion confetti and break sound (uses effect player, won't stop tap sound)
      _sparkController.play();
      _playBreakSound(); // Play IMMEDIATELY after tap sound - separate players handle it

      // Start Fly-Off sequence after a visual delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isFlyingOff) {
          setState(() { _isFlyingOff = true; });
          _setupFlyOffAnimation();
          _flyOffController.forward(from: 0.0);
        }
      });
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    if (_isCompletelyGone) {
      return const SizedBox.shrink();
    }

    final imagePath = _isBroken ? widget.brokenImagePath : widget.intactImagePath;

    return Stack(
      alignment: Alignment.center,
      children: [
        // --- Tap Spark Confetti Layers ---
        ...List.generate(_sparkControllers.length, (index) {
          final double angle = index * (2 * math.pi / _sparkControllers.length);
          final xPos = (widget.width / 2) + math.cos(angle) * (widget.width * 0.4) - 5;
          final yPos = (widget.height / 2) + math.sin(angle) * (widget.height * 0.4) - 5;
          return Positioned(
            left: xPos, top: yPos,
            child: ConfettiWidget(
              confettiController: _sparkControllers[index],
              blastDirection: angle + math.pi,
              blastDirectionality: BlastDirectionality.directional,
              particleDrag: 0.05, emissionFrequency: 0.05, numberOfParticles: 5,
              gravity: 0.1, colors: const [Colors.yellow, Colors.amber, Colors.orange, Colors.red],
              minimumSize: const Size(5, 15), maximumSize: const Size(10, 25),
              shouldLoop: false,
            ),
          );
        }),

        // --- Main Explosion Layer (Outside AnimatedBuilder) ---
        if (_isBroken)
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _sparkController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.02, emissionFrequency: 0.03, numberOfParticles: 300,
                maxBlastForce: 30, minBlastForce: 15, gravity: 0.2,
                colors: const [ Colors.yellow, Colors.amber, Colors.orange, Colors.red,
                                Colors.pink, Colors.purple, Colors.blue, Colors.green ],
                minimumSize: const Size(15, 15), maximumSize: const Size(30, 30),
                shouldLoop: false,
            ),
          ),

        // --- Pinata Image (Animated & Interactive) ---
        GestureDetector(
          onTap: () {
            _handleTap();
            widget.onTap?.call(); // Call the onTap callback if provided
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([ _wobbleController, _driftController, _flyOffController ]),
            builder: (context, child) {
              final wobbleAngle = (!_isBroken && !_isFlyingOff) ? _rotationAnimation.value * math.pi : 0.0;
              final driftAngle = (!_isBroken && !_isFlyingOff && _driftController.isAnimating) ? _driftAnimation.value * math.pi : 0.0;
              final flyOffOffset = _isFlyingOff ? Offset(_positionAnimation.value.dx * widget.width * 0.1, _positionAnimation.value.dy * widget.height * 0.1) : Offset.zero;
              final currentScale = _isFlyingOff ? _scaleAnimation.value : _initialScale;

              return Transform.translate(
                offset: flyOffOffset,
                child: Transform.scale(
                  scale: currentScale,
                  child: Transform.rotate( angle: wobbleAngle + driftAngle, child: child ),
                ),
              );
            },
            child: SizedBox(
              width: widget.width, height: widget.height,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $imagePath -> $error');
                  return Container(
                    width: widget.width, height: widget.height,
                    color: Colors.red.withOpacity(0.3),
                    child: const Center(child: Icon(Icons.error, color: Colors.white)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}