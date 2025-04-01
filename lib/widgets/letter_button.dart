import 'dart:async'; // Import async for Timer
import 'package:flutter/material.dart';
import '../config/game_config.dart'; // Ensure GameConfig is correctly imported

// --- LetterButton Widget ---
// This is the main stateful widget for the letter button.
class LetterButton extends StatefulWidget {
  final String letter; // The letter this button represents
  final VoidCallback onTap; // Action when the button is tapped
  final bool colored; // Whether the letter inside is visible/colored
  final bool draggable; // Whether the button can be dragged
  final bool isCorrectLetter; // Whether this letter matches the current target
  final ValueChanged<bool>? onDragSuccess; // Callback after drag ends, indicates correctness

  const LetterButton({
    super.key,
    required this.letter,
    required this.onTap,
    required this.isCorrectLetter, // Now required
    this.colored = false,
    this.draggable = false,
    this.onDragSuccess,
  });

  @override
  State<LetterButton> createState() => _LetterButtonState();
}

// --- _LetterButtonState ---
// This is the state associated with the LetterButton widget.
class _LetterButtonState extends State<LetterButton> {
  // State variable to track if this specific button has been successfully dragged away.
  bool _wasSuccessfullyDragged = false;

  // State variable to control the visibility of the incorrect feedback overlay.
  bool _showIncorrectFeedback = false;

  // Timer to automatically hide the feedback overlay after a duration.
  Timer? _feedbackTimer;

  @override
  void dispose() {
    // Clean up the timer when the widget is removed from the widget tree
    // to prevent memory leaks and errors.
    _feedbackTimer?.cancel();
    super.dispose();
  }

  // Method to trigger the temporary display of the incorrect feedback (sad emoji).
  void _showFeedbackAnimation() {
    // Ensure the widget is still mounted before updating state.
    if (!mounted) return;

    setState(() {
      // Make the feedback visible.
      _showIncorrectFeedback = true;
    });

    // Cancel any existing timer to reset the duration if triggered again quickly.
    _feedbackTimer?.cancel();

    // Start a new timer to hide the feedback after a set duration.
    _feedbackTimer = Timer(const Duration(milliseconds: 1200), () { // Feedback visible for 1.2 seconds
      // Ensure the widget is still mounted when the timer callback executes.
      if (mounted) {
        setState(() {
          // Hide the feedback.
          _showIncorrectFeedback = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant LetterButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Simpler, more aggressive reset:
    // If the button is now draggable (meaning it should be active for the current round)
    // AND its internal state still thinks it was dragged from a previous interaction,
    // force the state back to false.
    if (widget.draggable && _wasSuccessfullyDragged) {
      print("Resetting _wasSuccessfullyDragged for button '${widget.letter}' in didUpdateWidget because widget.draggable is now true.");
      // Reset the flag directly. A build is already happening due to the widget update.
      _wasSuccessfullyDragged = false;
    }

    // Reset feedback if the letter changes while feedback is showing
    if (widget.letter != oldWidget.letter && _showIncorrectFeedback) {
      _feedbackTimer?.cancel();
      // Reset feedback flag directly as well
      _showIncorrectFeedback = false;
    }
  }

  // --- Build Method ---
  // This method describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    // Calculate the button's size based on screen width and configuration factor.
    // Doing this once here avoids recalculating it multiple times.
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Check if device is likely an iPad (using aspect ratio and size)
    bool isIpad = mediaQuery.size.shortestSide >= 600 &&
                  (screenWidth / screenHeight).abs() < 1.6;
    
    // Adjust size factor for iPad - make it 20% smaller
    final sizeFactor = isIpad ? GameConfig.letterButtonSizeFactor * 0.8 : GameConfig.letterButtonSizeFactor;
    
    final buttonSize = screenWidth * sizeFactor;

    // --- Handle Dragged State ---
    // If the button was successfully dragged away previously, render an empty placeholder.
    if (_wasSuccessfullyDragged) {
      return _EmptyLetterCircle(buttonSize: buttonSize); // Pass size to the placeholder
    }

    // --- Build Button Visuals ---
    // Create the visual representation (the circle with the letter).
    final buttonVisual = _buildLetterCircle(context, buttonSize);

    // --- Build Interactive Element (Draggable or Tappable) ---
    // Determine if the button should be draggable or just tappable.
    Widget interactiveButton;
    if (widget.draggable) {
      // If draggable, wrap the visual in a Draggable widget.
      interactiveButton = Draggable<String>(
        data: widget.letter, // Data payload carried by the drag (the letter).
        feedback: _buildLetterCircle(context, buttonSize, isForFeedback: true), // Appearance while dragging.
        childWhenDragging: _EmptyLetterCircle(buttonSize: buttonSize), // Appearance in original spot while dragging.

        // --- Drag End Logic ---
        // Callback executed when the drag operation finishes.
        onDragEnd: (details) {
          // Determine if the drag was accepted by a target and if the letter was correct.
          bool wasCorrectlyAccepted = details.wasAccepted && widget.isCorrectLetter;
          bool wasIncorrectlyAccepted = details.wasAccepted && !widget.isCorrectLetter;

          if (wasCorrectlyAccepted) {
            // Dragged to the target, and it was the correct letter.
            print("Button '${widget.letter}' drag CORRECTLY accepted.");
            // Update state to visually remove the button from its original spot.
            if (mounted) { // Check mounted before setState
              setState(() { _wasSuccessfullyDragged = true; });
            }
            // Notify the parent screen/widget about the successful and correct drag.
            widget.onDragSuccess?.call(true);
          } else if (wasIncorrectlyAccepted) {
            // Dragged to the target, but it was the WRONG letter.
            print("Button '${widget.letter}' drag INCORRECTLY accepted.");
            // Trigger the visual feedback (sad emoji) on this button.
            _showFeedbackAnimation();
            // Notify the parent screen/widget that the drag was accepted but incorrect.
            widget.onDragSuccess?.call(false);
          } else {
            // Drag ended, but it wasn't dropped on an accepting target.
            print("Button '${widget.letter}' drag ended without acceptance.");
            // Optionally notify parent about the failed drop if needed:
            // widget.onDragSuccess?.call(false);
          }
        },
        // The actual widget that initiates the drag. Wrap the visual button.
        // Use GestureDetector to still allow tapping the button even when draggable.
        child: GestureDetector(
          onTap: widget.onTap,
          child: buttonVisual,
        ),
      );
    } else {
      // If not draggable, just wrap the visual button in a GestureDetector for tapping.
      interactiveButton = GestureDetector(
        onTap: widget.onTap,
        child: buttonVisual,
      );
    }

    // --- Final Widget Assembly with Feedback Overlay ---
    // Use a Stack to potentially layer the feedback emoji on top of the button.
    return Stack(
      alignment: Alignment.center, // Center the feedback overlay on the button.
      children: [
        // The base interactive button (either Draggable or GestureDetector).
        interactiveButton,

        // Conditionally add the feedback overlay if _showIncorrectFeedback is true.
        if (_showIncorrectFeedback)
          // Use IgnorePointer to prevent the overlay from blocking interactions
          // with the button underneath (though it's usually not interactable during feedback).
          IgnorePointer(
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  // Center the emoji within the overlay.
                  child: Center(
                    child: Text(
                      '😢', // The sad emoji character.
                      style: TextStyle(
                        fontSize: buttonSize * 0.75,
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        shadows: const [
                          Shadow(offset: Offset(-1, -1), color: Colors.black54),
                          Shadow(offset: Offset(1, -1), color: Colors.black54),
                          Shadow(offset: Offset(1, 1), color: Colors.black54),
                          Shadow(offset: Offset(-1, 1), color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- Helper Method to Build Button Visuals ---
  // Builds the circular container with the letter inside.
  Widget _buildLetterCircle(BuildContext context, double buttonSize, {bool isForFeedback = false}) {
    // Calculate font size based on button size and configuration factor.
    final double fontSize = buttonSize * GameConfig.letterButtonFontSizeFactor;
    // Determine if the button should appear visually active (influences decoration).
    final bool isButtonActive = isForFeedback || widget.draggable;
    // Determine if the letter text itself should be visible (colored).
    final bool showLetterText = isForFeedback || widget.colored;

    // Use a forced square layout with Material.shape to ensure circle shape
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        // Force circular shape with ShapeBorder
        shape: CircleBorder(
          side: BorderSide(
            color: isButtonActive 
                ? Colors.white.withOpacity(0.8) 
                : Colors.grey.withOpacity(0.4),
            width: 2.0,
          ),
        ),
        // Apply the gradient as elevation overlay color
        elevation: 4.0,
        shadowColor: Colors.black54,
        // Use Ink for gradient background that respects the CircleBorder shape
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isButtonActive 
                ? GameConfig.letterButtonGradient 
                : GameConfig.inactiveButtonGradient,
          ),
          child: Center(
            child: Text(
              widget.letter.toLowerCase(),
              style: GameConfig.letterButtonTextStyle.copyWith(
                fontSize: fontSize,
                color: showLetterText ? Colors.white : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- _EmptyLetterCircle Widget ---
// A simple stateless widget representing the empty space after a button
// has been successfully dragged away. Helps maintain layout consistency.
class _EmptyLetterCircle extends StatelessWidget {
  final double buttonSize; // Receives the size to match the original button.

  // Constructor requires the buttonSize. Use const for performance.
  const _EmptyLetterCircle({required this.buttonSize});

  @override
  Widget build(BuildContext context) {
    // Match the same pattern as the main button using Material+Ink for better shape control
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        // Force circular shape with ShapeBorder
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.grey.withOpacity(0.4),
            width: 2.0,
          ),
        ),
        elevation: 2.0, // Reduced elevation for inactive state
        shadowColor: Colors.black38,
        // Use Ink for gradient that respects the CircleBorder shape
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: GameConfig.inactiveButtonGradient,
          ),
        ),
      ),
    );
  }
}