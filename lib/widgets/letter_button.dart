import 'package:flutter/material.dart';
import '../config/game_config.dart';

class LetterButton extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  // final bool visible; // Removed - visibility controlled by parent AnimatedSwitcher
  final bool colored;
  final bool draggable;
  final ValueChanged<bool>? onDragSuccess; // Callback for drag success/failure

  const LetterButton({
    super.key,
    required this.letter,
    required this.onTap,
    // this.visible = true, // Removed
    this.colored = false,
    this.draggable = false,
    this.onDragSuccess,
  });

  @override
  State<LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<LetterButton> {
  // State to track if this specific button instance was successfully dragged away
  bool _wasSuccessfullyDragged = false;

  @override
  Widget build(BuildContext context) {
    // If this button was already successfully dragged, show the empty placeholder
    if (_wasSuccessfullyDragged) {
      // Use a constant empty circle for performance
      return const _EmptyLetterCircle();
    }

    // Build the visual representation of the button
    final buttonWidget = _buildLetterCircle(context);

    // If the button is meant to be draggable, wrap it in Draggable
    if (widget.draggable) {
      return Draggable<String>(
        data: widget.letter, // The data being dragged (the letter itself)
        // Feedback widget shown while dragging
        feedback: _buildLetterCircle(context, isForFeedback: true),
        // Widget shown in the original position while dragging
        childWhenDragging: const _EmptyLetterCircle(),
        // Called when the drag ends (dropped on a target or not)
        onDragEnd: (details) {
          // Check if the Draggable was accepted by a DragTarget
          if (details.wasAccepted) {
            print("Button '${widget.letter}' drag accepted by target.");
            // Update state to visually remove the button from its original spot
            if(mounted) { // Check if widget is still in tree before calling setState
              setState(() {
                _wasSuccessfullyDragged = true;
              });
            }
            // Notify the parent screen about the successful drag completion
            widget.onDragSuccess?.call(true);
          } else {
             print("Button '${widget.letter}' drag ended without acceptance.");
            // Optionally notify parent about unsuccessful drop if needed
            widget.onDragSuccess?.call(false);
          }
        },
        // The actual button widget that the user interacts with
        child: GestureDetector(
          onTap: widget.onTap, // Allow tapping even when draggable
          child: buttonWidget,
        ),
      );
    } else {
      // If not draggable, just make it tappable
      return GestureDetector(
        onTap: widget.onTap,
        child: buttonWidget,
      );
    }
  }

  // Helper method to build the circular button appearance
  Widget _buildLetterCircle(BuildContext context, {bool isForFeedback = false}) {
    // Calculate size and font size based on screen width and config
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;
    // Ensure GameConfig provides a font size factor relative to button size
    final double fontSize = buttonSize * GameConfig.letterButtonFontSizeFactor;

    // Determine appearance based on state
    // isActive might influence border/shadow in GameConfig.getLetterButtonDecoration
    final bool isButtonActive = isForFeedback || widget.draggable;
    // Show letter text if it's colored (meaning active/visible) or if it's the drag feedback
    final bool showLetterText = isForFeedback || widget.colored;

    // Use Material for ink effects if needed, otherwise Container is fine
    return Material(
      color: Colors.transparent, // Ensure Material doesn't add background
      shape: const CircleBorder(), // Ensures ripple effect is circular if onTap is used directly
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: GameConfig.getLetterButtonDecoration(
          context,
          isActive: isButtonActive, // Pass active state for styling
          // Removed isCorrect: null,
          // Removed isDragging: isForFeedback,
        ),
        child: Center(
          child: Text(
            widget.letter.toLowerCase(), // Display letter (always lowercase?)
            style: GameConfig.letterButtonTextStyle.copyWith(
              fontSize: fontSize,
              // Text is white when shown, potentially transparent otherwise (handled by Opacity if needed, but `showLetterText` controls rendering)
              color: showLetterText ? Colors.white : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

// A simple widget representing the empty space after a button is dragged away
class _EmptyLetterCircle extends StatelessWidget {
  const _EmptyLetterCircle(); // Can be const

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = screenWidth * GameConfig.letterButtonSizeFactor;

    // Return a container with the same size but styled as inactive/empty
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: GameConfig.getLetterButtonDecoration(
        context,
        isActive: false, // Explicitly inactive style
        // Removed isCorrect: null,
        // Removed isDragging: false,
      ),
      // No child needed, it's just an empty styled circle
    );
  }
}

// Ensure GameConfig contains:
// - letterButtonSizeFactor (e.g., 0.2)
// - letterButtonFontSizeFactor (e.g., 0.6 - relative to button size)
// - getLetterButtonDecoration (function returning BoxDecoration, accepting context and isActive)
// - letterButtonTextStyle (the base TextStyle)