import 'package:flutter/material.dart';

/// Modern fintech color palette for FinX app
/// Inspired by Cred, PhonePe, and modern banking apps
class FintechColors {
  // Private constructor
  FintechColors._();

  // ============ DARK THEME COLORS ============
  
  // Primary Backgrounds
  static const Color primaryBackground = Color(0xFF0F1115); // Deep charcoal
  static const Color secondaryBackground = Color(0xFF121417); // Slightly lighter
  static const Color cardBackground = Color(0xFF1A1D23); // Card surface
  static const Color surfaceColor = Color(0xFF252930); // Elevated surface
  
  // Accent Colors
  static const Color primaryBlue = Color(0xFF3B82F6); // Modern blue
  static const Color primaryPurple = Color(0xFF8B5CF6); // Accent purple
  static const Color accentGreen = Color(0xFF10B981); // Success/money
  static const Color accentRed = Color(0xFFEF4444); // Error/loss
  static const Color accentOrange = Color(0xFFF59E0B); // Warning/alert
  static const Color accentTeal = Color(0xFF14B8A6); // Info/analytics
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB3B8C8); // Muted white
  static const Color textMuted = Color(0xFF6B7280); // Very muted
  static const Color textOnPrimary = Color(0xFF000000); // Black on colored bg
  
  // UI Elements
  static const Color borderColor = Color(0xFF374151); // Subtle borders
  static const Color dividerColor = Color(0xFF1F2937); // Dividers
  static const Color shadowColor = Color(0x1A000000); // Subtle shadows
  static const Color overlayColor = Color(0x80000000); // Modal overlays
  
  // Status Colors with better contrast
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue
  
  // Category Colors for expenses
  static const Color foodColor = Color(0xFFF97316); // Orange
  static const Color travelColor = Color(0xFF06B6D4); // Cyan
  static const Color shoppingColor = Color(0xFFEC4899); // Pink
  static const Color billsColor = Color(0xFF8B5CF6); // Purple
  static const Color entertainmentColor = Color(0xFFF59E0B); // Yellow
  static const Color healthColor = Color(0xFF10B981); // Green
  static const Color othersColor = Color(0xFF6B7280); // Gray
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1D23), Color(0xFF252930)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Light theme fallback (optional)
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  
  // Aliases for compatibility
  static const Color darkBackground = primaryBackground;
  static const Color darkSurface = cardBackground;
  static const Color darkText = textPrimary;
  static const Color lightText = lightTextPrimary;
  static const Color primaryColor = primaryBlue;
  static const Color secondaryColor = primaryPurple;
  static const Color textTertiary = textMuted;
  
  // Helper method to get category color
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return foodColor;
      case 'travel':
        return travelColor;
      case 'shopping':
        return shoppingColor;
      case 'bills':
        return billsColor;
      case 'entertainment':
        return entertainmentColor;
      case 'health':
        return healthColor;
      default:
        return othersColor;
    }
  }
  
  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return successColor;
      case 'warning':
        return warningColor;
      case 'error':
        return errorColor;
      case 'info':
        return infoColor;
      default:
        return textMuted;
    }
  }
}