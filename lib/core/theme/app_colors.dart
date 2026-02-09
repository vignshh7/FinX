import 'package:flutter/material.dart';

/// Premium color palette following Material 3 guidelines
/// Inspired by: Google Pay, Cred, Apple Wallet
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============ PRIMARY COLORS ============
  
  /// Deep Indigo - Professional, trustworthy, premium
  static const Color primaryIndigo = Color(0xFF3949AB); // Indigo 600
  static const Color primaryIndigoLight = Color(0xFF5C6BC0); // Indigo 400
  static const Color primaryIndigoDark = Color(0xFF283593); // Indigo 800
  
  /// Emerald Green - Savings, positive, growth
  static const Color accentEmerald = Color(0xFF10B981); // Emerald 500
  static const Color accentEmeraldLight = Color(0xFF34D399); // Emerald 400
  static const Color accentEmeraldDark = Color(0xFF059669); // Emerald 600
  
  // ============ SEMANTIC COLORS ============
  
  /// Success - Savings, income, positive trends
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  
  /// Warning - Budget alerts, approaching limits
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  
  /// Error - Overspending, critical alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);
  
  /// Info - Analytics, insights, neutral information
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);
  
  // ============ LIGHT THEME COLORS ============
  
  static const Color backgroundLight = Color(0xFFFAFAFA); // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  static const Color textPrimaryLight = Color(0xFF1F2937); // Gray 800
  static const Color textSecondaryLight = Color(0xFF6B7280); // Gray 500
  static const Color textTertiaryLight = Color(0xFF9CA3AF); // Gray 400
  
  static const Color dividerLight = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFD1D5DB); // Gray 300
  
  // ============ DARK THEME COLORS ============
  
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF334155); // Slate 700
  
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Slate 300
  static const Color textTertiaryDark = Color(0xFF94A3B8); // Slate 400
  
  static const Color dividerDark = Color(0xFF475569); // Slate 600
  static const Color borderDark = Color(0xFF64748B); // Slate 500
  
  // ============ CATEGORY COLORS ============
  
  static const Color categoryFood = Color(0xFFEF4444); // Red
  static const Color categoryTravel = Color(0xFF3B82F6); // Blue
  static const Color categoryShopping = Color(0xFF8B5CF6); // Purple
  static const Color categoryBills = Color(0xFFF59E0B); // Amber
  static const Color categoryEntertainment = Color(0xFFEC4899); // Pink
  static const Color categoryHealth = Color(0xFF10B981); // Green
  static const Color categoryEducation = Color(0xFF6366F1); // Indigo
  static const Color categoryOther = Color(0xFF6B7280); // Gray
  
  // ============ CHART COLORS ============
  
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
  ];
  
  // ============ GRADIENT COLORS ============
  
  static const List<Color> primaryGradient = [
    Color(0xFF3949AB), // Indigo 600
    Color(0xFF5C6BC0), // Indigo 400
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF10B981), // Emerald 500
    Color(0xFF34D399), // Emerald 400
  ];
  
  static const List<Color> warningGradient = [
    Color(0xFFF59E0B), // Amber 500
    Color(0xFFFBBF24), // Amber 400
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFEF4444), // Red 500
    Color(0xFFF87171), // Red 400
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF10B981), // Emerald 500
    Color(0xFF34D399), // Emerald 400
  ];
  
  static const List<Color> infoGradient = [
    Color(0xFF3B82F6), // Blue 500
    Color(0xFF60A5FA), // Blue 400
  ];
  
  // ============ OVERLAY COLORS ============
  
  static const Color overlay = Color(0x66000000); // 40% black
  static const Color overlayLight = Color(0x33000000); // 20% black
  static const Color overlayDark = Color(0x99000000); // 60% black
  
  // ============ CONVENIENCE ALIASES ============
  
    // NOTE: Prefer the adaptive helpers below in UI code.
    static Color get textSecondary => textSecondaryLight;

    // ============ ADAPTIVE HELPERS ============

    static bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

    static Color textPrimaryColor(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;

    static Color textSecondaryColor(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;

    static Color textTertiaryColor(BuildContext context) =>
      _isDark(context) ? textTertiaryDark : textTertiaryLight;

    static Color backgroundColor(BuildContext context) =>
      _isDark(context) ? backgroundDark : backgroundLight;

    static Color surfaceColor(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceLight;

    static Color cardColor(BuildContext context) =>
      _isDark(context) ? cardDark : cardLight;

    static Color dividerColor(BuildContext context) =>
      _isDark(context) ? dividerDark : dividerLight;

    static Color borderColor(BuildContext context) =>
      _isDark(context) ? borderDark : borderLight;
  
  // ============ HELPER METHODS ============
  
  /// Get category color by category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return categoryFood;
      case 'travel':
        return categoryTravel;
      case 'shopping':
        return categoryShopping;
      case 'bills':
        return categoryBills;
      case 'entertainment':
        return categoryEntertainment;
      case 'health':
        return categoryHealth;
      case 'education':
        return categoryEducation;
      default:
        return categoryOther;
    }
  }
  
  /// Get confidence color (green for high, yellow for medium, red for low)
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.7) {
      return success;
    } else if (confidence >= 0.4) {
      return warning;
    } else {
      return error;
    }
  }
  
  /// Get spending status color (green under budget, red over budget)
  static Color getSpendingStatusColor(double spent, double budget) {
    final percentage = spent / budget;
    if (percentage < 0.7) {
      return success;
    } else if (percentage < 0.9) {
      return warning;
    } else {
      return error;
    }
  }
}
