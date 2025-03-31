import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service.dart'; // Assuming AudioService path

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

class _FireworksScreenState extends State<FireworksScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate fireworks animation and then complete after 3 seconds
    Timer(const Duration(seconds: 3), () {
       if (mounted) {
         widget.onComplete();
       }
    });
     // Optional: Play a firework sound here if you have one
     // widget.audioService.playShortSoundEffect('assets/audio/other/fireworks.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Example background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text('🎆', style: TextStyle(fontSize: 100)), // Placeholder emoji
             const SizedBox(height: 20),
             const Text(
              'Awesome!',
              style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            // TODO: Add a real fireworks animation widget here (e.g., using a package)
          ],
        ),
      ),
    );
  }
}
