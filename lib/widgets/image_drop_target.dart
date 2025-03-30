import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_item.dart';
import '../config/game_config.dart';
import '../services/audio_service.dart';
import '../services/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
  
  // Get AudioService from the widget tree instead of creating a new instance
  AudioService? _getAudioService() {
    try {
      return Provider.of<AudioService>(context, listen: false);
    } catch (e) {
      return null;
    }
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
  
  // Build the word overlay
  Widget _buildWordOverlay() {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Text(
        widget.item.word.toLowerCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          color: Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
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
                return Container(
                  width: availableWidth,
                  height: containerHeight,
                  // Remove padding to allow image to take up full container
                  decoration: BoxDecoration(
                    // Remove border radius for edge-to-edge display
                  ),
                  // Modified: Keep ClipRRect only for overlays but not for the main container
                  child: Stack(
                    children: [
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
                      
                      // Word overlay
                      _buildWordOverlay(),
                      
                      // Hover indicator
                      if (isHovering) Positioned.fill(child: _buildHoverIndicator()),
                    ],
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