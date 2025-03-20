import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameConfig {
  // Animation durations
  static const Duration letterRevealDelay = Duration(seconds: 1);
  static const Duration dropAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 500);
  
  // Size constants
  static const double letterButtonSize = 240.0;
  static const double letterButtonRadius = 120.0;
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
  static final Color primaryButtonColor = Colors.blue.shade100;
  static final Color highlightColor = Colors.green.shade100;
  static final Color defaultBackgroundColor = Colors.white;
  static final Color highlightBorderColor = Colors.green;
  static final Color defaultBorderColor = Colors.grey;
  
  // Text styles
  static TextStyle get letterTextStyle => GoogleFonts.aBeeZee(
    fontSize: letterFontSize,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get wordTextStyle => GoogleFonts.aBeeZee(
    fontSize: wordFontSize,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get titleTextStyle => GoogleFonts.aBeeZee(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get bodyTextStyle => GoogleFonts.aBeeZee(
    fontSize: bodyTextFontSize,
  );
  
  // Common box decorations
  static BoxDecoration getCardDecoration({bool isHighlighted = false}) {
    return BoxDecoration(
      color: isHighlighted ? highlightColor : defaultBackgroundColor,
      border: Border.all(
        color: isHighlighted ? highlightBorderColor : defaultBorderColor,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(defaultBorderRadius),
    );
  }
}