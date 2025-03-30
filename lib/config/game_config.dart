import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameConfig {
  // --- General --- 
  static const double defaultPadding = 0.0;
  static const double defaultBorderRadius = 0.0;
  
  // --- App Colors ---
  static final Color defaultBackgroundColor = Color.fromARGB(255, 255, 247, 17); // Soft warm pink
  static final Color defaultBorderColor = Color(0xFFDEE2E6); // Light gray
  static final Color textColor = Color(0xFF2B2D42); // Dark blue-gray
  static final Color cardBackgroundColor = defaultBackgroundColor; // Use the same pink for cards
  static final Color dialogBackgroundColor = defaultBackgroundColor; // Use the same pink for dialogs
  static final Color scaffoldBackgroundColor = defaultBackgroundColor; // Use the same pink for scaffolds
  static final Color appBarBackgroundColor = Colors.transparent; // Transparent app bar
  static final Color systemNavigationBarColor = defaultBackgroundColor; // Use the same pink for system navigation bar
  
  // --- Layout Flex Values ---
  static const int imageAreaFlex = 3; // Flex value for the image area in layout
  static const int letterButtonsFlex = 2; // Flex value for the letter buttons area in layout
  
  // --- Gradient ---
  static final LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      defaultBackgroundColor,
      defaultBackgroundColor.withOpacity(0.9),
    ],
  );
  static TextStyle get bodyTextStyle => GoogleFonts.fredoka(
    fontSize: bodyTextFontSize,
    color: textColor,
  );
  static const double bodyTextFontSize = 18.0;

  // --- Timing --- 
  // All animation durations set to zero to remove animations
  static const Duration dropAnimationDuration = Duration.zero;
  static const Duration fadeAnimationDuration = Duration.zero;
  // Sequence timing - set to zero to remove delays
  static const Duration betweenLettersDelay = Duration.zero;
  static const Duration afterLettersDelay = Duration.zero;
  static const Duration letterLoadDelay = Duration.zero;
  static const Duration uiUpdateDelay = Duration.zero;

  // --- Image Drop Target (Image Area) --- 
  static const double imageHeight = 300.0; // Used?
  static const double imageDropWordFontSize = 150.0; // Font size for word shown on tap
  static const double imageDropTargetPadding = 0.0; // Internal padding (NEW)
  // (Red Flash animation handled internally in ImageDropTarget state)
  // (Scale animation handled internally in ImageDropTarget state)

  // --- Letter Buttons --- 
  static const double letterButtonSizeFactor = 0.25; // Factor of screen width
  static const double letterButtonPaddingFactor = 0.025; // Factor of screen width for horizontal padding
  static const double letterFontSize = 180.0; // Base size for letter in button (scaled by button size)
  static final Color primaryButtonColor = Color(0xFF4CC9F0);  // Active button background
  static final Color inactiveButtonColor = Color(0xFFADB5BD); // Inactive/empty button background
  static final LinearGradient letterButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryButtonColor,
      primaryButtonColor.withAlpha((0.8 * 255).toInt()),
    ],
  );
  static final LinearGradient inactiveButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      inactiveButtonColor,
      inactiveButtonColor.withAlpha((0.8 * 255).toInt()),
    ],
  );
  // Text style used *inside* the letter button (color/shadows)
  static TextStyle get letterButtonTextStyle => GoogleFonts.fredoka(
    // Note: Font size is calculated dynamically in LetterButton widget
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(2.0, 2.0),
        blurRadius: 3.0,
        color: Colors.black26,
      ),
    ],
  );
  // Decoration used by LetterButton widget
  static BoxDecoration getLetterButtonDecoration(BuildContext context, {bool isActive = true}) {
    final buttonSize = MediaQuery.of(context).size.width * letterButtonSizeFactor;
    return BoxDecoration(
      gradient: isActive ? letterButtonGradient : inactiveButtonGradient,
      // Make border radius dependent on button size
      borderRadius: BorderRadius.circular(buttonSize * 0.5), // Perfect circle
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.05 * 255).toInt()),
          spreadRadius: isActive ? 2 : 1,
          blurRadius: isActive ? 5 : 3, 
          offset: Offset(0, isActive ? 4 : 2),
        ),
      ],
      border: Border.all(
        color: isActive 
            ? primaryButtonColor.withAlpha((0.8 * 255).toInt())
            : inactiveButtonColor.withAlpha((0.8 * 255).toInt()),
        width: isActive ? 2 : 1,
      ),
    );
  }
  
  // --- Word Display (Below Image - Specific Context?) ---
  // TODO: Clarify where wordTextStyle/wordFontSize are used if not on image tap
  static const double wordFontSize = 50.0;
  static TextStyle get wordTextStyle => GoogleFonts.fredoka(
    fontSize: wordFontSize,
    fontWeight: FontWeight.bold,
    color: textColor, 
  );

  // --- Correct Answer Display (In Image Area) --- 
  static const double correctLetterFontSize = 300.0; // Font size for the big letter shown on correct answer
  // Uses letterButtonGradient for background
  // Uses letterButtonTextStyle for text style (but overrides fontSize)

  // --- Generic UI Elements (e.g., Cards, Titles) ---
  static const double titleFontSize = 25.0;
  static TextStyle get titleTextStyle => GoogleFonts.fredoka(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  static final Color secondaryButtonColor = Color(0xFF7209B7); // Example: Maybe used on WelcomeScreen
  static final Color highlightColor = Color(0xFF4DE1C1);  // Used in card decoration highlight
  static final Color highlightBorderColor = Color(0xFF06D6A0); // Used in card decoration highlight
  // Decoration used for generic cards (e.g., maybe on WelcomeScreen or future screens)
  static BoxDecoration getCardDecoration({bool isHighlighted = false}) {
    return BoxDecoration(
      gradient: isHighlighted ? 
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlightColor,
            highlightColor.withAlpha((0.8 * 255).toInt()),
          ],
        ) : 
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            defaultBackgroundColor,
            defaultBackgroundColor.withAlpha((0.9 * 255).toInt()),
          ],
        ),
      borderRadius: BorderRadius.circular(defaultBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.05 * 255).toInt()),
          spreadRadius: 1,
          blurRadius: 5,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isHighlighted ? highlightBorderColor : defaultBorderColor,
        width: 2,
      ),
    );
  }

  // --- Audio --- 
  static const int maxQuestionVariations = 1; // Number of question audio files per word/general

  // --- Deprecated / Unused? ---
  // static const double letterSpacing = 30.0; // Appears unused, vertical spacing handled by SizedBoxes

}