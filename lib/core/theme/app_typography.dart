import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium typography system following Material 3 guidelines
/// Uses Google Fonts for professional appearance
class AppTypography {
  // Private constructor
  AppTypography._();

  // ============ FONT FAMILIES ============
  
  /// Primary font - Inter (clean, modern, professional)
  static String primaryFont = 'Inter';
  
  /// Accent font - Poppins (friendly, rounded)
  static String accentFont = 'Poppins';
  
  /// Monospace font - JetBrains Mono (numbers, amounts)
  static String monoFont = 'JetBrainsMono';
  
  // ============ FONT WEIGHTS ============
  
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  
  // ============ TEXT STYLES - DISPLAY ============
  
  /// Display Large - Hero numbers, amounts
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: bold,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  /// Display Medium - Large headers
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: bold,
    height: 1.16,
    letterSpacing: 0,
  );
  
  /// Display Small - Section headers
  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
  );
  
  // ============ TEXT STYLES - HEADLINE ============
  
  /// Headline Large - Page titles
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
  );
  
  /// Headline Medium - Card titles
  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.29,
    letterSpacing: 0,
  );
  
  /// Headline Small - Subtitles
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0,
  );
  
  // ============ TEXT STYLES - TITLE ============
  
  /// Title Large - List titles
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: medium,
    height: 1.27,
    letterSpacing: 0,
  );
  
  /// Title Medium - Dialogs, sheets
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  /// Title Small - Section labels
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  // ============ TEXT STYLES - BODY ============
  
  /// Body Large - Primary body text
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  /// Body Medium - Secondary body text
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  /// Body Small - Captions, hints
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // ============ TEXT STYLES - LABEL ============
  
  /// Label Large - Buttons, chips
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  /// Label Medium - Tabs, badges
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  /// Label Small - Timestamps, metadata
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  // ============ CUSTOM STYLES ============
  
  /// Amount - Large monetary values
  static TextStyle amount = GoogleFonts.jetBrainsMono(
    fontSize: 32,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// Amount Small - Smaller monetary values
  static TextStyle amountSmall = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: -0.25,
  );
  
  /// Amount Tiny - List items, cards
  static TextStyle amountTiny = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
  );
  
  /// Button Large - Primary buttons
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  /// Button Medium - Secondary buttons
  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  /// Chip - Category chips, tags
  static TextStyle chip = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  /// Overline - Section headers, labels
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: semiBold,
    height: 1.6,
    letterSpacing: 1.5,
  );
  
  // ============ TEXT THEME ============
  
  /// Get Material 3 text theme
  static TextTheme getTextTheme({required bool isDark}) {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
  
  // ============ CONVENIENCE ALIASES ============
  
  // Short aliases for common usage
  static TextStyle get h1 => displayLarge;
  static TextStyle get h2 => displayMedium;
  static TextStyle get h3 => displaySmall;
  static TextStyle get h4 => headlineLarge;
  static TextStyle get h5 => headlineMedium;
  static TextStyle get h6 => headlineSmall;
  
  static TextStyle get bodyLg => bodyLarge;
  static TextStyle get bodyMd => bodyMedium;
  static TextStyle get bodySm => bodySmall;
  
  static TextStyle get labelLg => labelLarge;
  static TextStyle get labelMd => labelMedium;
  static TextStyle get labelSm => labelSmall;
}
