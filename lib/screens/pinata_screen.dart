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
  // final _random = Random(); // Keep if you plan other random elements

  @override
  void initState() {
    super.initState();
    // Any initial setup if needed
  }

  @override
  Widget build(BuildContext context) {
    // Define pinata dimensions for consistency
    const double pinataWidth = 300.0;
    const double pinataHeight = 300.0;

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
            // Back button
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
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
                            onCompletelyGone: () {
                              // Ensure the widget is still mounted before updating state
                              if (mounted) {
                                setState(() {
                                  _pinataCompletelyGone = true;
                                });
                              }
                            },
                            audioService: widget.audioService,
                            requiredTaps: 3, // Or configure as needed
                          ),
                        ),

                      // NEXT WORD button
                      if (_pinataCompletelyGone)
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
                                      color: Colors.black.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4), // Slightly more shadow
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2) // Optional border
                                ),
                                child: const Text(
                                  'NEXT WORD', // Using uppercase for button convention
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}