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
    this.requiredTaps = 3, // Default value
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
  bool _confettiFinished = false; // Track if confetti animation has finished
  bool _explosionTriggered = false; // Flag to ensure explosion happens once

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
    _scaleAnimation = ConstantTween<double>(_initialScale).animate(_flyOffController);
    _positionAnimation = ConstantTween<Offset>(Offset.zero).animate(_flyOffController);
    _flyOffController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
             if (_confettiFinished) {
                 if (!_isCompletelyGone) {
                     setState(() { _isCompletelyGone = true; });
                     widget.onCompletelyGone?.call();
                 }
             }
          }
        }
     });

    // --- Confetti Setup ---
    _sparkController = ConfettiController(duration: const Duration(milliseconds: 2500));
    _sparkController.addListener(() {
      if (_sparkController.state == ConfettiControllerState.stopped && _isBroken && !_confettiFinished) {
          if (mounted) {
              setState(() { _confettiFinished = true; });
              _checkAnimationsComplete();
          }
      }
    });

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
    _positionAnimation = Tween<Offset>(begin: Offset.zero, end: _flyOffDirection * 20.0)
        .animate(CurvedAnimation(parent: _flyOffController, curve: Curves.easeOutExpo));
  }

  // --- Sound Playback Helpers ---
  void _playTapSound() {
     widget.audioService.playPinataTap().catchError((e) => print("Error playing tap sound: $e"));
  }

  void _playBreakSound() {
     widget.audioService.playPinataBreak().catchError((e) => print("Error playing break sound: $e"));
  }

  // --- Main Interaction Logic ---
  void _handleTap() {
    if (!mounted || _isBroken || _isFlyingOff || _isCompletelyGone) return;

    setState(() { _tapCount++; });

    _playTapSound();

    // Show tap spark effect randomly
    if (_sparkControllers.isNotEmpty) {
        final index = _random.nextInt(_sparkControllers.length);
        // *** REMOVED .isDisposed CHECK ***
        _sparkControllers[index].play();
    }

    // Trigger wobble animation
    if (!_wobbleController.isAnimating) {
        _setupRotationAnimation();
        _wobbleController.forward(from: 0.0);
    }

    // --- Check for Break Condition (Final Tap) ---
    if (_tapCount >= widget.requiredTaps && !_explosionTriggered) {
      _explosionTriggered = true;

      print("Pinata breaking! Tap count: $_tapCount");

      // Set state and call callbacks
      setState(() { _isBroken = true; });
      widget.onBroken();
      _driftController.stop();

      // Play explosion confetti & sound (Guarded by flag)
      // *** REMOVED .isDisposed CHECK ***
      _sparkController.play();
      _playBreakSound();

      // Delayed start for fly-off
      Future.delayed(const Duration(milliseconds: 100), () {
         if (mounted && !_isFlyingOff) {
             print("Starting fly-off animation...");
             setState(() { _isFlyingOff = true; });
             _setupFlyOffAnimation();
             _flyOffController.forward(from: 0.0);
         }
      });
    }
  }


  // Check if both fly-off and confetti are complete
  void _checkAnimationsComplete() {
     if (mounted && _confettiFinished && _flyOffController.isCompleted && !_isCompletelyGone) {
         print("Both fly-off and confetti finished.");
         setState(() { _isCompletelyGone = true; });
         widget.onCompletelyGone?.call();
     }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    if (_isCompletelyGone) {
      return const SizedBox.shrink();
    }

    final imagePath = _isBroken ? widget.brokenImagePath : widget.intactImagePath;

    // Confetti Parameters
    const int tapSparkParticles = 5;
    const Size tapSparkMinSize = Size(5, 15);
    const Size tapSparkMaxSize = Size(10, 25);
    const int explosionParticles = 300;
    const double explosionMaxForce = 30;
    const double explosionMinForce = 15;
    const Size explosionMinSize = Size(15, 15);
    const Size explosionMaxSize = Size(30, 30);

    return Stack(
      alignment: Alignment.center,
      children: [
        // --- Tap Spark Confetti Layers ---
        ...List.generate(_sparkControllers.length, (index) {
          final double angle = index * (2 * math.pi / _sparkControllers.length);
          final xPos = (widget.width / 2) + math.cos(angle) * (widget.width * 0.4);
          final yPos = (widget.height / 2) + math.sin(angle) * (widget.height * 0.4);
          return Positioned(
            left: xPos - (tapSparkMaxSize.width / 2),
            top: yPos - (tapSparkMaxSize.height / 2),
            child: ConfettiWidget(
              confettiController: _sparkControllers[index],
              blastDirection: angle + math.pi,
              blastDirectionality: BlastDirectionality.directional,
              particleDrag: 0.05, emissionFrequency: 0.05,
              numberOfParticles: tapSparkParticles,
              gravity: 0.1,
              colors: const [Colors.yellow, Colors.amber, Colors.orange, Colors.red],
              minimumSize: tapSparkMinSize, maximumSize: tapSparkMaxSize,
              shouldLoop: false,
            ),
          );
        }),

        // --- Pinata Image (Animated & Interactive) ---
        GestureDetector(
          onTap: () {
            widget.onTap?.call();
            _handleTap();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_wobbleController, _driftController, _flyOffController]),
            builder: (context, child) {
              final wobbleAngle = (!_isBroken && !_isFlyingOff && _wobbleController.isAnimating) ? _rotationAnimation.value * math.pi : 0.0;
              final driftAngle = (!_isBroken && !_isFlyingOff && _driftController.isAnimating) ? _driftAnimation.value * math.pi : 0.0;
              final flyOffOffset = _isFlyingOff ? Offset(_positionAnimation.value.dx * widget.width * 0.1, _positionAnimation.value.dy * widget.height * 0.1) : Offset.zero;
              final currentScale = _isFlyingOff ? _scaleAnimation.value : _initialScale;
              return Transform.translate(
                offset: flyOffOffset,
                child: Transform.scale(
                  scale: currentScale.clamp(0.0, _initialScale * 1.1),
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
                  print('Error loading pinata image: $imagePath -> $error');
                  return Container(
                    width: widget.width, height: widget.height,
                    decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.red.withOpacity(0.3), ),
                    child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 40)),
                  );
                },
              ),
            ),
          ),
        ),

        // --- Main Explosion Layer ---
         if (_explosionTriggered)
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _sparkController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.02, emissionFrequency: 0.03,
                numberOfParticles: explosionParticles,
                maxBlastForce: explosionMaxForce, minBlastForce: explosionMinForce,
                gravity: 0.2,
                colors: const [ Colors.yellow, Colors.amber, Colors.orange, Colors.red, Colors.pink, Colors.purple, Colors.blue, Colors.green ],
                minimumSize: explosionMinSize, maximumSize: explosionMaxSize,
                shouldLoop: false,
            ),
          ),
      ],
    );
  } // End of build
} // End of _PinataWidgetState