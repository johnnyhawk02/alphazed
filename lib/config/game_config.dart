import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameConfig {
  // Animation durations
  static const Duration letterRevealDelay = Duration(milliseconds: 1500);
  static const Duration dropAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 500);
  
  // Size constants
  static const double letterButtonSize = 200.0;
  static const double letterButtonRadius = 100.0;
  static const double imageHeight = 300.0;
  static const double letterSpacing = 30.0;
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 16.0;
  
  // Text and font sizes
  static const int maxQuestionVariations = 5;
  static const double letterFontSize = 120.0;
  static const double wordFontSize = 50.0;
  static const double titleFontSize = 22.0;
  static const double bodyTextFontSize = 18.0;
  
  // Colors
  static final Color primaryButtonColor = Color(0xFF4CC9F0);  // Bright blue
  static final Color secondaryButtonColor = Color(0xFF7209B7); // Deep purple
  static final Color highlightColor = Color(0xFF4DE1C1);  // Turquoise
  static final Color defaultBackgroundColor = Color(0xFFF8F9FA); // Light gray
  static final Color highlightBorderColor = Color(0xFF06D6A0); // Mint
  static final Color defaultBorderColor = Color(0xFFDEE2E6); // Light gray
  static final Color textColor = Color(0xFF2B2D42); // Dark blue-gray
  
  static final LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8F9FA),
      Color(0xFFE9ECEF),
    ],
  );
  
  static final LinearGradient letterButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryButtonColor,
      primaryButtonColor.withOpacity(0.8),
    ],
  );
  
  // Text styles
  static TextStyle get letterTextStyle => GoogleFonts.fredoka(
    fontSize: letterFontSize,
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
  
  static TextStyle get wordTextStyle => GoogleFonts.fredoka(
    fontSize: wordFontSize,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get titleTextStyle => GoogleFonts.fredoka(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle get bodyTextStyle => GoogleFonts.fredoka(
    fontSize: bodyTextFontSize,
    color: textColor,
  );
  
  // Common box decorations
  static BoxDecoration getCardDecoration({bool isHighlighted = false}) {
    return BoxDecoration(
      gradient: isHighlighted ? 
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlightColor,
            highlightColor.withOpacity(0.8),
          ],
        ) : 
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            defaultBackgroundColor,
            defaultBackgroundColor.withOpacity(0.9),
          ],
        ),
      borderRadius: BorderRadius.circular(defaultBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isHighlighted ? highlightBorderColor : defaultBorderColor,
        width: 2,
      ),
    );
  }
  
  static BoxDecoration getLetterButtonDecoration({bool isActive = true}) {
    return BoxDecoration(
      gradient: isActive ? letterButtonGradient : null,
      color: isActive ? null : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(letterButtonRadius),
      boxShadow: isActive ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 0,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ] : null,
    );
  }
}