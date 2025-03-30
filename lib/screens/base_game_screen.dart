import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';

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
  bool get fullScreenMode => true; // Override this in subclasses to enable full-screen mode
  
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

  // Common app bar without back button
  PreferredSizeWidget buildGameAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 70,
      automaticallyImplyLeading: false, // Disable back button
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
          appBar: fullScreenMode ? null : buildGameAppBar(), // Hide app bar in full-screen mode
          backgroundColor: GameConfig.defaultBackgroundColor,
          body: Consumer2<GameState, AudioService>(
            builder: (context, gameState, audioService, _) {
              if (gameState.currentItem == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final Widget content = buildPortraitLayout(gameState, audioService);
              
              // Return content directly if in full-screen mode
              if (fullScreenMode) {
                return content;
              }
              
              // Otherwise, use the default padding and SafeArea
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: GameConfig.defaultPadding),
                  child: content,
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