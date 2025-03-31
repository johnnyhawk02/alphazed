// This file contains a development utility for generating app icons.
// It is commented out to prevent it from being included in production builds.
// Uncomment this file when you need to generate new app icons during development.

/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../config/game_config.dart';

class IconGeneratorScreen extends StatefulWidget {
  const IconGeneratorScreen({super.key});
  @override
  State<IconGeneratorScreen> createState() => _IconGeneratorScreenState();
}

class _IconGeneratorScreenState extends State<IconGeneratorScreen> {
  bool _isGenerating = false;
  bool _isComplete = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // This disables the back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // App icon preview
                    Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Icon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      GameConfig.primaryButtonColor,
                                      GameConfig.primaryButtonColor.withOpacity(0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'A',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 90,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Splash screen preview
                    Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Splash Screen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'AlphaZed',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: GameConfig.primaryButtonColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      5,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              GameConfig.primaryButtonColor,
                                              GameConfig.primaryButtonColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index),
                                            style: const TextStyle(
                                              fontFamily: 'Fredoka',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Instructions
                    Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '1. Click "Generate Icons" to create app icon files\n'
                              '2. Icons will be saved to assets/icons folder\n'
                              '3. Run the following commands in terminal:\n'
                              '   • flutter pub get\n'
                              '   • dart run flutter_launcher_icons\n'
                              '   • dart run flutter_native_splash:create\n'
                              '4. Your app is now ready for submission!',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isComplete ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Generate button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateIcons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameConfig.primaryButtonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Generate Icons'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateIcons() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating icons...';
      _isComplete = false;
    });

    try {
      // Create the icons directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String appIconsDir = '${Directory.current.path}/assets/icons';
      final Directory iconsDir = Directory(appIconsDir);
      
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }
      
      // Use existing image as base for app icon
      final appIconPath = '$appIconsDir/app_icon.png';
      final splashIconPath = '$appIconsDir/splash_icon.png';
      
      // Simple method - copy from assets to disk
      await _copyAssetToDisk('assets/images/apple.jpeg', appIconPath);
      await _copyAssetToDisk('assets/images/apple.jpeg', splashIconPath);
      
      setState(() {
        _isGenerating = false;
        _isComplete = true;
        _statusMessage = 'Icons generated successfully! Files saved to:\n'
            '- $appIconPath\n'
            '- $splashIconPath\n\n'
            'Now run these commands in terminal:\n'
            '1. dart run flutter_launcher_icons\n'
            '2. dart run flutter_native_splash:create';
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = 'Error generating icons: $e';
      });
    }
  }
  
  Future<void> _copyAssetToDisk(String assetPath, String targetPath) async {
    try {
      // Load the bundled asset
      final ByteData data = await rootBundle.load(assetPath);
      
      // Extract to bytes and save to disk
      final File file = File(targetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), 
        flush: true
      );
    } catch (e) {
      print('Error copying asset to disk: $e');
      rethrow;
    }
  }
}
*/