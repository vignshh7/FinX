import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern fintech typography system for FinX app
/// Uses Inter font for professional, clean appearance
class FintechTypography {
  // Private constructor
  FintechTypography._();

  // Font Family - Inter for clean, professional look
  static String get fontFamily => 'Inter';
  
  // ============ HEADINGS ============
  
  /// Hero text for main amounts and key metrics
  static TextStyle get hero => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.0,
  );
  
  /// Large heading for screen titles
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// Section headings
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );
  
  /// Subsection headings
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  /// Card titles and labels
  static TextStyle get h4 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  /// Small headings
  static TextStyle get h5 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  /// Tiny headings
  static TextStyle get h6 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  // ============ BODY TEXT ============
  
  /// Main body text
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Secondary body text
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Small body text
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // ============ LABELS ============
  
  /// Button labels and form labels
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Small labels
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Tiny labels and captions
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  // ============ SPECIAL TEXT STYLES ============
  
  /// Captions and hints
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  
  /// Overline text (categories, tags)
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 1.5,
  );
  
  // ============ BUTTON TEXT ============
  
  /// Large button text
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  
  /// Medium button text
  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  /// Small button text
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  // ============ FINANCIAL/NUMERIC TEXT ============
  
  /// Large currency amounts (tabular figures for alignment)
  static TextStyle get currencyLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  /// Medium currency amounts
  static TextStyle get currencyMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  /// Small currency amounts
  static TextStyle get currencySmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  /// Tiny currency amounts
  static TextStyle get currencyTiny => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  // ============ NAVIGATION ============
  
  /// Bottom navigation labels
  static TextStyle get navLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  /// Tab bar labels
  static TextStyle get tabLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // ============ FORMS ============
  
  /// Input field text
  static TextStyle get inputText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Input field hints
  static TextStyle get inputHint => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  /// Input field labels
  static TextStyle get inputLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
  );
  
  // ============ STATUS ============
  
  /// Success messages
  static TextStyle get success => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Error messages
  static TextStyle get error => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Warning messages
  static TextStyle get warning => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  /// Info messages
  static TextStyle get info => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}