import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class AppIconGenerator {
  // Generate app icon and save it to assets/icons folder
  static Future<bool> generateAppIcon(BuildContext context) async {
    try {
      // Create the icon widget
      final iconWidget = _buildAppIcon();
      
      // Render the icon to an image
      final iconBytes = await _renderWidgetToImage(iconWidget, 1024);
      if (iconBytes == null) return false;
      
      // Save the icon
      final iconFile = File('${Directory.current.path}/assets/icons/app_icon.png');
      await iconFile.writeAsBytes(iconBytes);
      print('App icon saved to: ${iconFile.path}');
      
      // Create the splash widget
      final splashWidget = _buildSplashScreen();
      
      // Render the splash to an image
      final splashBytes = await _renderWidgetToImage(splashWidget, 1024);
      if (splashBytes == null) return false;
      
      // Save the splash
      final splashFile = File('${Directory.current.path}/assets/icons/splash_icon.png');
      await splashFile.writeAsBytes(splashBytes);
      print('Splash screen saved to: ${splashFile.path}');
      
      return true;
    } catch (e) {
      print('Error generating app icons: $e');
      return false;
    }
  }
  
  // Render a widget to a PNG image
  static Future<Uint8List?> _renderWidgetToImage(Widget widget, double size) async {
    final repaintBoundary = RenderRepaintBoundary();
    
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        size: Size(size, size),
        devicePixelRatio: 1.0,
      ),
    );
    
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();
    
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);
    
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    
    final image = await repaintBoundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List();
  }
  
  // Build the app icon widget
  static Widget _buildAppIcon() {
    return Container(
      width: 1024,
      height: 1024,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CC9F0),
            Color(0xFF4CC9F0).withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'A',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 600,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(10, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build the splash screen widget
  static Widget _buildSplashScreen() {
    return Container(
      width: 1024,
      height: 1024,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'AlphaZed',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CC9F0),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4CC9F0),
                      Color(0xFF4CC9F0).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(5, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 80,
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
    );
  }
}