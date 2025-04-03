import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../widgets/pinata_widget.dart';

class PinataScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback onComplete; // Make this required

  const PinataScreen({
    Key? key,
    required this.audioService,
    required this.onComplete, // Mark as required
  }) : super(key: key);

  @override
  State<PinataScreen> createState() => _PinataScreenState();
}

class _PinataScreenState extends State<PinataScreen> {
  // State to track when the pinata has finished its fly-off animation
  bool _pinataCompletelyGone = false;
  // State to track when to show the next button (after delay)
  bool _showNextButton = false;
  // Track the current tap count for the countdown display
  int _tapCount = 0;
  final int _requiredTaps = 6;
  
  void _incrementTapCount() {
    setState(() {
      _tapCount++;
    });
  }

  @override
  void initState() {
    super.initState();
    // Reset tap count when screen initializes
    _tapCount = 0;
  }
  
  // Add delay and show button
  void _handlePinataAnimationComplete() {
    if (mounted) {
      setState(() {
        _pinataCompletelyGone = true;
      });
      
      // Increase delay to ensure confetti animation has fully completed visually
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showNextButton = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pinata dimensions based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final pinataWidth = screenWidth * 0.7; // Changed from 0.4 to 0.7
    final pinataHeight = pinataWidth; // Keep it square for proper aspect ratio

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pinata/pinata_courtyard.png'),
            fit: BoxFit.cover, // Use cover to fill the screen better
            alignment: Alignment.center,
          ),
        ),
        child: Stack(
          children: [
            // Background dimmer overlay
            Container(
              color: Colors.black.withAlpha((0.4 * 255).toInt()),
              width: double.infinity,
              height: double.infinity,
            ),

            // Back button
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.4 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () {
                    // Call onComplete callback directly
                    widget.onComplete();
                  },
                ),
              ),
            ),

            // Center pinata area
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate center position - ensures it works regardless of screen size/orientation
                  final centerX = constraints.maxWidth / 2;
                  final centerY = constraints.maxHeight / 2;

                  return Stack(
                    children: [
                      // Pinata widget - Positioned precisely in the center
                      // Only build the PinataWidget if it's not completely gone
                      if (!_pinataCompletelyGone)
                        Positioned(
                          // Adjust position based on pinata dimensions to center it
                          left: centerX - (pinataWidth / 2),
                          top: centerY - (pinataHeight / 2),
                          child: PinataWidget(
                            width: pinataWidth,
                            height: pinataHeight,
                            intactImagePath: 'assets/images/pinata/pinata_intact.png',
                            brokenImagePath: 'assets/images/pinata/pinata_broken.png',
                            // onBroken is called immediately when the break starts
                            onBroken: () {
                              // Optional: Add minor feedback here if needed (e.g., haptics)
                              // print("Pinata breaking sequence started!");
                            },
                            // onCompletelyGone is called when the fly-off animation finishes
                            onCompletelyGone: _handlePinataAnimationComplete,
                            audioService: widget.audioService,
                            requiredTaps: _requiredTaps, // Changed from 3 to 6 hits to explode
                            onTap: _incrementTapCount, // Increment tap count on tap
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Countdown display in top right corner
            if (!_pinataCompletelyGone)
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  width: screenWidth * 0.2, // 20% of screen width
                  height: screenWidth * 0.2, // Square aspect ratio
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.7 * 255).toInt()),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.5 * 255).toInt()),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${_requiredTaps - _tapCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.12, // Increased size now that we only have the number
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // NEXT WORD button
            if (_showNextButton)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      // Call onComplete callback directly
                      widget.onComplete();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600, // Slightly adjusted color
                        borderRadius: BorderRadius.circular(30), // More rounded
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.4 * 255).toInt()),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4), // Slightly more shadow
                          ),
                        ],
                        border: Border.all(color: Colors.white.withAlpha((0.8 * 255).toInt()), width: 2) // Optional border
                      ),
                      child: const Text(
                        'next word', // Using lowercase for consistent styling
                        style: TextStyle(
                          fontSize: 36, // Slightly smaller font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5, // Adjusted letter spacing
                          shadows: [ // Add text shadow for depth
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 2.0,
                              color: Colors.black38,
                            ),
                          ]
                        ),
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