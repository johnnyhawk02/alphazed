import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../config/game_config.dart';

class IconGenerator extends StatefulWidget {
  const IconGenerator({super.key});

  @override
  State<IconGenerator> createState() => _IconGeneratorState();
}

class _IconGeneratorState extends State<IconGenerator> {
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _splashKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    // Delay to ensure widget is rendered before capturing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _captureLauncherIcon();
        _captureSplashLogo();
      });
    });
  }
  
  Future<void> _captureLauncherIcon() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final file = File('${Directory.current.path}/assets/launcher_icon.png');
        await file.writeAsBytes(pngBytes);
        print('Launcher icon saved to: ${file.path}');
      }
    } catch (e) {
      print('Error capturing launcher icon: $e');
    }
  }
  
  Future<void> _captureSplashLogo() async {
    try {
      RenderRepaintBoundary boundary = _splashKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final file = File('${Directory.current.path}/assets/splash_logo.png');
        await file.writeAsBytes(pngBytes);
        print('Splash logo saved to: ${file.path}');
      }
    } catch (e) {
      print('Error capturing splash logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Launcher Icon Design
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 512,
                height: 512,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GameConfig.primaryButtonColor,
                      GameConfig.primaryButtonColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 300,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Splash Logo Design
            RepaintBoundary(
              key: _splashKey,
              child: Container(
                width: 512,
                height: 512,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AlphaZed',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: GameConfig.primaryButtonColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                GameConfig.primaryButtonColor,
                                GameConfig.primaryButtonColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 40,
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
            ),
          ],
        ),
      ),
    );
  }
}