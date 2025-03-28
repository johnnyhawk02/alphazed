import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';

// Common back button painter
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final centerY = size.height / 2;
    final arrowWidth = size.width * 1.5;
    
    final path = Path()
      ..moveTo(size.width * 0.95, centerY - arrowWidth / 2)
      ..lineTo(size.width * 0.05, centerY)
      ..lineTo(size.width * 0.95, centerY + arrowWidth / 2);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract class BaseGameScreen extends StatefulWidget {
  final String title;
  
  const BaseGameScreen({
    super.key,
    required this.title,
  });
  
  @override
  BaseGameScreenState createState();
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends State<T>
    with WidgetsBindingObserver {
      
  final GlobalKey _targetContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Layout methods that must be implemented by subclasses
  Widget buildPortraitLayout(GameState gameState, AudioService audioService);
  Widget buildLetterGrid(GameState gameState, AudioService audioService);

  // Common app bar with back button
  PreferredSizeWidget buildGameAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 70,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: ArrowPainter(),
          ),
        ),
      ),
      title: Text(
        (widget as BaseGameScreen).title,
        style: GameConfig.titleTextStyle,
      ),
    );
  }

  // Base build method that implements the common structure
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: buildGameAppBar(),
          backgroundColor: GameConfig.defaultBackgroundColor,
          body: Consumer2<GameState, AudioService>(
            builder: (context, gameState, audioService, _) {
              if (gameState.currentItem == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: GameConfig.defaultPadding),
                  child: buildPortraitLayout(gameState, audioService),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Utility getter for subclasses
  GlobalKey get targetContainerKey => _targetContainerKey;
}