import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';
import '../services/theme_provider.dart';

class ImageDropTarget extends StatefulWidget {
  final GameItem item;
  final Function(String) onLetterAccepted;
  
  const ImageDropTarget({
    super.key,
    required this.item,
    required this.onLetterAccepted,
  });
  
  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> with TickerProviderStateMixin {
  // Constants for styling
  static const double _borderRadius = 0.0;
  
  bool isHovering = false;
  String? correctLetter;
  bool showWord = false;
  bool isPressed = false;
  
  // Audio service for playing word sounds
  final AudioService _audioService = AudioService();
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // Handle press down
  void _handleTapDown(TapDownDetails details) async {
    setState(() {
      isPressed = true;
      showWord = true;
    });
    
    // Play the word audio immediately on press
    await _audioService.playWord(widget.item.word);
  }

  // Handle press up
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      isPressed = false;
    });
    
    // Keep word visible for 1 second after release
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          showWord = false;
        });
      }
    });
  }

  // Handle tap cancel
  void _handleTapCancel() {
    setState(() {
      isPressed = false;
      showWord = false;
    });
  }
  
  // Build the hover indicator
  Widget _buildHoverIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.8 * 255).toInt()),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_circle_outline,
          size: 60,
          color: GameConfig.primaryButtonColor,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // For 1:1 ratio, height should equal width
        final double containerHeight = availableWidth;
        
        // Main stack: DragTarget first, Confetti on top
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // DragTarget containing the image/letter/word display
            DragTarget<String>(
              onWillAcceptWithDetails: (data) {
                setState(() => isHovering = true);
                return true;
              },
              onLeave: (_) {
                setState(() => isHovering = false);
              },
              onAcceptWithDetails: (data) {
                setState(() => isHovering = false);
                
                // Check if the dropped letter is correct
                final isCorrect = data.data.toLowerCase() == widget.item.firstLetter.toLowerCase();
                
                // Flash red for incorrect, green for correct
                if (isCorrect) {
                  context.read<ThemeProvider>().flashCorrect();
                } else {
                  context.read<ThemeProvider>().flashIncorrect();
                }
                
                // We don't set correctLetter anymore, even for correct answers
                widget.onLetterAccepted(data.data);
              },
              builder: (context, candidateData, rejectedData) {
                return GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  child: Container(
                    width: availableWidth,
                    height: containerHeight,
                    // Remove padding to allow image to take up full container
                    // padding: EdgeInsets.all(GameConfig.imageDropTargetPadding),
                    decoration: BoxDecoration(
                      // Remove border radius for edge-to-edge display
                      // borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    // Modified: Keep ClipRRect only for overlays but not for the main container
                    child: Stack(
                      children: [
                        // Show the word when pressed or for 1 second after release
                        if (showWord)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    GameConfig.primaryButtonColor.withOpacity(isPressed ? 0.8 : 1.0),
                                    GameConfig.primaryButtonColor.withOpacity(isPressed ? 0.6 : 0.8),
                                  ],
                                ),
                              ),
                              // Use Padding and FittedBox for dynamic text sizing
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.contain, // Scale down to fit
                                    child: Text(
                                      widget.item.word,
                                      style: GameConfig.wordTextStyle.copyWith(
                                        // Remove fixed font size, FittedBox handles sizing
                                        // fontSize: GameConfig.imageDropWordFontSize, 
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center, 
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          // Image - No ClipRRect to allow edge-to-edge display
                          Positioned.fill(
                            child: Opacity(
                              opacity: isHovering ? 0.7 : 1.0,
                              child: Image.asset(
                                widget.item.imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        
                        // Hover indicator
                        if (isHovering) Positioned.fill(child: _buildHoverIndicator()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}