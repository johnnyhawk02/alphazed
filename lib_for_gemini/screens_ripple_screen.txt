import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Keep for Gradient
import '../services/audio_service.dart';

// --- Helper Class for a Single Ripple (_InkRipple) ---
// (Keep this class exactly the same as before)
class _InkRipple {
  final int id;
  final Offset center;
  final AnimationController controller;
  final Color color;
  final double maxRadius;
  final double startRadius;
  final Function(int) onComplete;
  bool _listenerAdded = false;

  _InkRipple({ required this.id, required this.center, required this.controller, required this.color, required this.maxRadius, required this.startRadius, required this.onComplete, }) { _addStatusListenerOnce(); }
  void _addStatusListenerOnce() { if (!_listenerAdded) { try { controller.addStatusListener(_statusListener); _listenerAdded = true; } catch (e) { print("Error adding ripple status listener: $e"); } } }
  void _statusListener(AnimationStatus status) { if (status == AnimationStatus.completed) { onComplete(id); _removeStatusListenerOnce(); } }
  void _removeStatusListenerOnce() { if (_listenerAdded) { try { controller.removeStatusListener(_statusListener); _listenerAdded = false; } catch (e) { _listenerAdded = false; } } }
}


// --- Main Ripple Screen Widget ---
class RippleScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onComplete;

  const RippleScreen({ Key? key, required this.audioService, required this.onComplete, }) : super(key: key);

  @override
  State<RippleScreen> createState() => _RippleScreenState();
}

class _RippleScreenState extends State<RippleScreen> with TickerProviderStateMixin {
  final List<_InkRipple> _ripples = [];
  final Random _random = Random();
  Timer? _completionTimer;
  bool _showNextButton = false;

  // Track if sound is currently playing to prevent cutting it off
  bool _isSoundPlaying = false;

  final List<Color> _psychedelicColors = [ Colors.pinkAccent, Colors.purpleAccent, Colors.cyanAccent, Colors.limeAccent, Colors.deepOrangeAccent, Colors.lightBlueAccent, Colors.greenAccent, Colors.redAccent, Colors.amberAccent, ];
  final String _plopSoundPath = 'assets/audio/other/plop.mp3';
  final String _waaarbSoundPath = 'assets/audio/other/waaaarb.mp3';

  @override
  void initState() {
    super.initState();
    _completionTimer = Timer(const Duration(seconds: 8), () { if (mounted) { setState(() { _showNextButton = true; }); } });
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (mounted) { 
        // Play the waaaarb sound when the screen first loads
        _playSoundWithoutCutting(_waaarbSoundPath);
        
        final size = MediaQuery.of(context).size;
        _addRipple(size.center(Offset.zero));
      }
    });
  }

  // New method to play sounds without cutting them off
  void _playSoundWithoutCutting(String soundPath) {
    if (_isSoundPlaying) return;
    
    setState(() {
      _isSoundPlaying = true;
    });
    
    try {
      widget.audioService.playShortSoundEffect(soundPath, stopPreviousEffect: false)
        .then((_) {
          // Reset flag when sound finishes playing
          if (mounted) {
            setState(() {
              _isSoundPlaying = false;
            });
          }
        });
    } catch (e) {
      print("Error playing sound ($soundPath): $e");
      // Reset flag if there's an error
      if (mounted) {
        setState(() {
          _isSoundPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    print("RippleScreen disposing...");
    _completionTimer?.cancel();
    print("Disposing ${_ripples.length} ripple controllers...");
    for (var ripple in List.from(_ripples)) { try { ripple.controller.dispose(); } catch (e) { /* ignore */ } }
    _ripples.clear();
    print("RippleScreen dispose complete.");
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (!mounted || _showNextButton) return;
    
    // Play the waaaarb sound when user taps, using the method that prevents cutting off
    _playSoundWithoutCutting(_waaarbSoundPath);
    
    _addRipple(details.localPosition);
  }

  void _addRipple(Offset position) {
    if (!mounted) return;
    final double startRadius = 5.0 + _random.nextDouble() * 15.0;
    final double maxRadius = MediaQuery.of(context).size.width * (0.4 + _random.nextDouble() * 0.5);
    final Color color = _psychedelicColors[_random.nextInt(_psychedelicColors.length)];
    final Duration duration = Duration(milliseconds: 1500 + _random.nextInt(1500)); // Slightly shorter max duration

    AnimationController? controller;
    try {
      if (!mounted) return;
      controller = AnimationController(duration: duration, vsync: this);
      final ripple = _InkRipple( id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000), center: position, controller: controller, color: color, maxRadius: maxRadius, startRadius: startRadius,
        onComplete: (id) { if (mounted) { setState(() { _ripples.removeWhere((r) => r.id == id); }); } },
      );
      if (mounted) { setState(() { _ripples.add(ripple); }); controller.forward(); } else { controller.dispose(); }
    } catch (e) { print("Error creating/starting ripple animation: $e"); controller?.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.grey[900]!;
    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // --- Simplified Ripple Painter ---
            CustomPaint(
              // Use the NEW SimplifiedRipplePainter
              painter: _SimplifiedRipplePainter(
                ripples: List.from(_ripples), // Pass copy
              ),
              size: Size.infinite,
            ),

            // --- NEXT WORD Button --- (Logic remains the same)
            if (_showNextButton)
              Positioned.fill( child: Center( child: GestureDetector( onTap: () { _completionTimer?.cancel(); widget.onComplete(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.shade400,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.5 * 255).toInt()),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha((0.7 * 255).toInt()),
                        width: 2
                      )
                    ),
                    child: const Text( 'NEXT WORD', style: TextStyle( fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5, shadows: [ Shadow( offset: Offset(1.0, 1.0), blurRadius: 2.0, color: Colors.black45, ), ] ), ),
                  ), ), ),
              ),

            // Back button (Keep for usability)
            Positioned( top: 40, left: 20, child: Container( decoration: BoxDecoration( color: Colors.black.withAlpha((0.4 * 255).toInt()), shape: BoxShape.circle, ),
                child: IconButton( icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () { _completionTimer?.cancel(); widget.onComplete(); }, ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- SIMPLIFIED Custom Painter for Ripples ---
class _SimplifiedRipplePainter extends CustomPainter {
  final List<_InkRipple> ripples;

  // Constructor listens to controllers for repaint triggers
  _SimplifiedRipplePainter({required this.ripples})
      : super(repaint: Listenable.merge(ripples.map((r) => r.controller).toList()));

  final Paint _paint = Paint(); // Reuse paint object

  @override
  void paint(Canvas canvas, Size size) {
    // NO saveLayer, NO BlendMode.plus needed

    for (final ripple in ripples) {
      try {
        // Check status before accessing value
        if (ripple.controller.status == AnimationStatus.dismissed) continue;

        final progress = ripple.controller.value;
        final curvedProgress = Curves.easeOutCubic.transform(progress);

        final currentRadius = ui.lerpDouble(ripple.startRadius, ripple.maxRadius, curvedProgress)!;
        final opacity = pow(1.0 - progress, 1.5).clamp(0.0, 1.0).toDouble();

        if (opacity <= 0.0 || currentRadius <= 0.0) continue;

        final Color currentColor = ripple.color.withAlpha((opacity * 255).toInt());

        // Configure paint with gradient ONLY
        _paint.shader = ui.Gradient.radial(
          ripple.center,
          currentRadius,
          [
            currentColor, // Center color with opacity
            currentColor.withAlpha(0), // Fade to transparent
          ],
          [ 0.0, 1.0 ] // Gradient stops (Center to Edge)
        );
        _paint.maskFilter = null; // Ensure NO blur is applied

        // Draw directly onto the main canvas
        canvas.drawCircle(ripple.center, currentRadius, _paint);

      } catch (e) {
        print("Error painting simplified ripple (id ${ripple.id}): $e");
      }
    }
    // NO canvas.restore() needed
  }

  @override
  bool shouldRepaint(covariant _SimplifiedRipplePainter oldDelegate) {
    // Repaint primarily handled by the Listenable.merge
    return ripples.length != oldDelegate.ripples.length;
  }
}