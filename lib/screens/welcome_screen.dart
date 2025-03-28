import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';
import 'letter_to_picture_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Alphabet Learning',
          style: GameConfig.titleTextStyle,
        ),
        actions: [
          // Developer option button
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () => _showDeveloperOptions(context),
            tooltip: 'Developer Options',
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LetterPictureMatch(),
              ),
            );
          },
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(GameConfig.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap anywhere to start!',
                    style: GameConfig.titleTextStyle.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    Icons.touch_app,
                    size: 60,
                    color: GameConfig.primaryButtonColor,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeveloperOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Options'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDevOption(
                context,
                title: 'Clear Asset Caches',
                description: 'Clear all audio and image caches to reload fresh assets',
                icon: Icons.cleaning_services,
                onTap: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  
                  // Show loading indicator
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Clearing asset caches...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Get AudioService from provider and clear caches
                  final audioService = Provider.of<AudioService>(context, listen: false);
                  await audioService.clearAssetCaches();
                  
                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Asset caches cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              _buildDevOption(
                context,
                title: 'Clear Sound Caches Only',
                description: 'Clear only audio assets to reload fresh sounds',
                icon: Icons.music_note,
                onTap: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  
                  // Show loading indicator
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Clearing sound caches...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Get AudioService from provider and clear sound caches
                  final audioService = Provider.of<AudioService>(context, listen: false);
                  await audioService.clearSoundCaches();
                  
                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sound caches cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDevOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: GameConfig.primaryButtonColor),
        title: Text(title),
        subtitle: Text(description),
        onTap: onTap,
      ),
    );
  }
}