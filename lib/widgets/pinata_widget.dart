import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import '../services/audio_service.dart';

class PinataWidget extends StatefulWidget {
  final double width;
  final double height;
  final String intactImagePath;
  final String brokenImagePath;
  final Function(bool animationsComplete) onBroken;
  final int requiredTaps;
  final AudioService audioService;
  
  const PinataWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.intactImagePath,
    required this.brokenImagePath,
    required this.onBroken,
    required this.audioService,
    this.requiredTaps = 3,
  }) : super(key: key);
  
  @override
  State<PinataWidget> createState() => _PinataWidgetState();
}

class _PinataWidgetState extends State<PinataWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isBroken = false;
  int _tapCount = 0;
  bool _animationsComplete = false;
  bool _audioComplete = false;
  
  // Confetti controllers for spark effects
  late ConfettiController _sparkController;
  final List<ConfettiController> _sparkControllers = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && _tapCount >= widget.requiredTaps && !_isBroken) {
        setState(() {
          _isBroken = true;
        });
        
        // Play the big explosion effect when the piñata breaks
        _sparkController.play();
        
        // Listen for when the confetti animation is complete
        _sparkController.addListener(_checkAnimationComplete);
        
        // Play a celebratory sound when the piñata breaks and track when it finishes
        _playBreakSound();
        
        // Call onBroken immediately, but with false to indicate animations aren't complete yet
        widget.onBroken(false);
      }
    });

    // Initialize the main spark controller with longer duration for the big explosion
    _sparkController = ConfettiController(duration: const Duration(milliseconds: 2500));
    
    // Create multiple spark controllers for different tap locations
    for (int i = 0; i < 5; i++) {
      _sparkControllers.add(ConfettiController(duration: const Duration(milliseconds: 300)));
    }
  }

  void _playBreakSound() async {
    try {
      await widget.audioService.playAudio('assets/audio/other/correct.mp3');
      // Mark audio as complete and check if we can proceed
      _audioComplete = true;
      _checkIfAllComplete();
    } catch (e) {
      // In case of error, still mark as complete to avoid blocking
      _audioComplete = true;
      _checkIfAllComplete();
    }
  }
  
  void _checkAnimationComplete() {
    // Check if animation is complete
    if (_sparkController.state == ConfettiControllerState.stopped && !_animationsComplete) {
      _sparkController.removeListener(_checkAnimationComplete);
      _animationsComplete = true;
      _checkIfAllComplete();
    }
  }
  
  void _checkIfAllComplete() {
    if (_animationsComplete && _audioComplete) {
      // Now all animations and audio are complete
      if (mounted) {
        // Notify parent that everything is complete
        widget.onBroken(true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkController.dispose();
    for (var controller in _sparkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (_isBroken) return;
    
    setState(() {
      _tapCount++;
    });
    
    // Play spark effect at a random location
    final index = _random.nextInt(_sparkControllers.length);
    _sparkControllers[index].play();
    
    // Play a hitting sound effect
    widget.audioService.playAudio('assets/audio/other/bell.mp3');
    
    // Play swing animation
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main confetti emitter in the center
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _sparkController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            gravity: 0.2,
            colors: const [
              Colors.yellow,
              Colors.orange,
              Colors.red,
            ],
            minimumSize: const Size(5, 5),
            maximumSize: const Size(8, 8),
            shouldLoop: false,
          ),
        ),
        
        // Multiple spark emitters positioned around the piñata
        ...List.generate(5, (index) {
          final double angle = index * (math.pi / 3);
          final xPos = math.cos(angle) * (widget.width * 0.4);
          final yPos = math.sin(angle) * (widget.height * 0.4);
          
          return Positioned(
            left: widget.width / 2 + xPos - 5,
            top: widget.height / 2 + yPos - 5,
            child: ConfettiWidget(
              confettiController: _sparkControllers[index],
              blastDirection: math.pi / 2 + angle, // Direction angle
              blastDirectionality: BlastDirectionality.directional,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 5,
              gravity: 0.1,
              colors: const [
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.red,
              ],
              minimumSize: const Size(3, 10), // Spark-like elongated particles
              maximumSize: const Size(5, 15),
              shouldLoop: false,
            ),
          );
        }),
        
        // The actual piñata widget with tap detection
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * math.pi,
                child: child,
              );
            },
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Image.asset(
                _isBroken ? widget.brokenImagePath : widget.intactImagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        // Big final explosion when the piñata breaks
        if (_isBroken)
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _sparkController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.red,
                Colors.pink,
                Colors.purple,
              ],
              shouldLoop: false,
            ),
          ),
      ],
    );
  }
}