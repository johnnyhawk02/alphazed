import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameConfig {
  // --- General ---
  static const double defaultPadding = 0.0;
  static const double defaultBorderRadius = 0.0;

  // --- Loading Screen ---
  static const double loadingIndicatorWidth = 0.6; // 60% of screen width
  static const double loadingIndicatorHeight = 10.0;
  static const double loadingTextSpacing = 20.0;
  static BorderRadius loadingIndicatorBorderRadius = BorderRadius.circular(10);

  // --- App Colors ---
  static final Color defaultBackgroundColor = Color(0xFFBCB8B8); // Updated to #BCB8B8 (light gray)
  static final Color defaultBorderColor = Color(0xFFDEE2E6); // Light gray
  static final Color textColor = Color(0xFF2B2D42); // Dark blue-gray
  static final Color cardBackgroundColor = defaultBackgroundColor; // Use the same pink for cards
  static final Color dialogBackgroundColor = defaultBackgroundColor; // Use the same pink for dialogs
  static final Color scaffoldBackgroundColor = defaultBackgroundColor; // Use the same pink for scaffolds
  static final Color appBarBackgroundColor = Colors.transparent; // Transparent app bar
  static final Color systemNavigationBarColor = defaultBackgroundColor; // Use the same pink for system navigation bar

  // --- Layout Flex Values ---
  //static const int imageAreaFlex = 3; // Default flex value for the image area in layout (legacy)
  //static const int letterButtonsFlex = 2; // Default flex value for the letter buttons area in layout (legacy)
  
  // Device-specific flex values
  static const int ipadImageAreaFlex = 7; // Flex value for image area on iPad
  static const int ipadLetterButtonsFlex = 3; // Flex value for letter buttons area on iPad
  static const int iphoneImageAreaFlex = 3; // Flex value for image area on iPhone
  static const int iphoneLetterButtonsFlex = 2; // Flex value for letter buttons area on iPhone

  // --- Gradient ---
  static final LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      defaultBackgroundColor,
      defaultBackgroundColor.withAlpha((0.9 * 255).toInt()),
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
  static const double ipadImageWidthFactor = 0.7; // Image width factor for iPad (70% of screen width)
  // (Red Flash animation handled internally in ImageDropTarget state)
  // (Scale animation handled internally in ImageDropTarget state)

  // --- Letter Buttons ---
  static const double letterButtonSizeFactor = 0.25; // Factor of screen width
  static const double letterButtonPaddingFactor = 0.025; // Factor of screen width for horizontal padding
  // *** ADD THIS LINE ***
  static const double letterButtonFontSizeFactor = 0.6; // Font size as factor of button size (e.g., 60%)
  // static const double letterFontSize = 180.0; // This absolute value is likely confusing/unused, consider removing
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
    // Note: Font size is calculated dynamically in LetterButton widget using the factor
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Check if device is likely an iPad (using aspect ratio and size)
    bool isIpad = mediaQuery.size.shortestSide >= 600 &&
                  (screenWidth / screenHeight).abs() < 1.6;
    
    // Adjust size factor for iPad - make it 20% smaller
    final sizeFactor = isIpad ? letterButtonSizeFactor * 0.8 : letterButtonSizeFactor;
    
    final buttonSize = screenWidth * sizeFactor;
    
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
  // Add path for correct sound
  static const String correctSoundPath = 'assets/audio/other/correct.mp3';

  // --- Deprecated / Unused? ---
  // static const double letterSpacing = 30.0; // Appears unused, vertical spacing handled by SizedBoxes

  // --- Game State Initialization ---
  static const int initialIndex = 0;
  static const bool initialImageVisibility = false;
  static const bool initialLettersDraggable = false;
  static const int initialVisibleLetterCount = 0;
  static const int initialColoredLetterCount = 0;

  // --- Developer Options ---
  static const bool enableDeveloperOptions = true;
  static const String developerOptionsTitle = 'Developer Options';
  static const IconData developerOptionsIcon = Icons.developer_mode;
  static const bool showCelebrationScreens = true;
}