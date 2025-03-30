import 'package:flutter/material.dart';
import '../widgets/pinata_widget.dart';
import '../services/audio_service.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class PinataScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PinataScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PinataScreen> createState() => _PinataScreenState();
}

class _PinataScreenState extends State<PinataScreen> {
  bool _isAnimationComplete = false;

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                '¡Rompe la piñata!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 40),
              PinataWidget(
                width: 300,
                height: 300,
                intactImagePath: 'assets/images/pinata/pinata_intact.png',
                brokenImagePath: 'assets/images/pinata/pinata_broken.png',
                audioService: audioService,
                requiredTaps: 3,
                onBroken: (animationsComplete) {
                  if (animationsComplete) {
                    setState(() {
                      _isAnimationComplete = true;
                    });
                    
                    // Show celebration message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Fiesta! The pinata broke! 🎉'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Wait a moment then continue
                    Future.delayed(const Duration(seconds: 3), () {
                      widget.onComplete();
                    });
                  }
                },
              ),
              const SizedBox(height: 40),
              if (_isAnimationComplete)
                ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}