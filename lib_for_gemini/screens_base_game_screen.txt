import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/game_config.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/theme_provider.dart'; // Add ThemeProvider
import '../widgets/color_picker_dialog.dart'; // Add the color picker dialog

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
  bool get fullScreenMode => false; // Override this in subclasses to enable full-screen mode
  
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
      actions: [
        // Add the color options menu
        IconButton(
          icon: const Icon(Icons.color_lens),
          onPressed: () {
            _showColorPickerDialog();
          },
        ),
      ],
    );
  }
  
  // Show the color picker dialog
  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => const ColorPickerDialog(),
    );
  }

  // Base build method that implements the common structure
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Stack(
              children: [
                Scaffold(
                  appBar: fullScreenMode ? null : buildGameAppBar(), // Hide app bar in full-screen mode
                  backgroundColor: themeProvider.backgroundColor,
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
                        // Add extra top padding for mobile
                        top: true,
                        minimum: const EdgeInsets.only(top: 40.0),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: GameConfig.defaultPadding),
                          child: content,
                        ),
                      );
                    },
                  ),
                ),
                // Flash overlay for feedback
                if (themeProvider.flashColor != null && themeProvider.flashOpacity > 0)
                  Positioned.fill(
                    child: Container(
                      color: themeProvider.flashColor!.withAlpha((themeProvider.flashOpacity * 255).toInt()),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  // Utility getter for subclasses
  GlobalKey get targetContainerKey => _targetContainerKey;
}