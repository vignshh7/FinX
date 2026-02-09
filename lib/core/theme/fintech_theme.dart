import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fintech_colors.dart';
import 'fintech_typography.dart';

/// Modern fintech theme for FinX app
/// Professional dark theme inspired by Cred, PhonePe, and modern banking apps
class FintechTheme {
  // Private constructor
  FintechTheme._();

  /// Modern dark theme optimized for finance apps
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: FintechTypography.fontFamily,
      
      // ============ COLOR SCHEME ============
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: FintechColors.primaryBlue,
        onPrimary: FintechColors.textOnPrimary,
        primaryContainer: FintechColors.primaryPurple,
        onPrimaryContainer: FintechColors.textPrimary,
        
        secondary: FintechColors.accentGreen,
        onSecondary: FintechColors.textOnPrimary,
        secondaryContainer: FintechColors.successColor,
        onSecondaryContainer: FintechColors.textPrimary,
        
        tertiary: FintechColors.accentTeal,
        onTertiary: FintechColors.textOnPrimary,
        tertiaryContainer: FintechColors.infoColor,
        onTertiaryContainer: FintechColors.textPrimary,
        
        error: FintechColors.errorColor,
        onError: FintechColors.textPrimary,
        errorContainer: FintechColors.errorColor,
        onErrorContainer: FintechColors.textPrimary,
        
        background: FintechColors.primaryBackground,
        onBackground: FintechColors.textPrimary,
        surface: FintechColors.cardBackground,
        onSurface: FintechColors.textPrimary,
        surfaceVariant: FintechColors.surfaceColor,
        onSurfaceVariant: FintechColors.textSecondary,
        
        outline: FintechColors.borderColor,
        outlineVariant: FintechColors.dividerColor,
        shadow: FintechColors.shadowColor,
        scrim: FintechColors.overlayColor,
      ),
      
      // ============ SCAFFOLD ============
      scaffoldBackgroundColor: FintechColors.primaryBackground,
      
      // ============ APP BAR ============
      appBarTheme: AppBarTheme(
        backgroundColor: FintechColors.primaryBackground,
        foregroundColor: FintechColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: FintechTypography.h4.copyWith(
          color: FintechColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: FintechColors.textPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: FintechColors.textPrimary,
          size: 24,
        ),
        centerTitle: false,
        titleSpacing: 20,
      ),
      
      // ============ CARDS ============
      cardTheme: CardThemeData(
        color: FintechColors.cardBackground,
        shadowColor: FintechColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(0), // Let individual cards control margins
        clipBehavior: Clip.antiAlias,
      ),
      
      // ============ BUTTONS ============
      
      // Elevated Buttons (Primary Actions)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FintechColors.primaryBlue,
          foregroundColor: FintechColors.textPrimary,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: FintechTypography.buttonMedium,
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Text Buttons (Secondary Actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FintechColors.primaryBlue,
          textStyle: FintechTypography.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 44),
        ),
      ),
      
      // Outlined Buttons (Tertiary Actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FintechColors.textPrimary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: FintechColors.borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: FintechTypography.buttonMedium,
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FintechColors.primaryBlue,
        foregroundColor: FintechColors.textPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
      ),
      
      // ============ INPUTS ============
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FintechColors.surfaceColor,
        
        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.errorColor, width: 2),
        ),
        
        // Text styles
        labelStyle: FintechTypography.inputLabel.copyWith(
          color: FintechColors.textSecondary,
        ),
        floatingLabelStyle: FintechTypography.inputLabel.copyWith(
          color: FintechColors.primaryBlue,
        ),
        hintStyle: FintechTypography.inputHint.copyWith(
          color: FintechColors.textMuted,
        ),
        helperStyle: FintechTypography.caption.copyWith(
          color: FintechColors.textMuted,
        ),
        errorStyle: FintechTypography.caption.copyWith(
          color: FintechColors.errorColor,
        ),
        
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: false,
      ),
      
      // ============ NAVIGATION ============
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FintechColors.cardBackground,
        selectedItemColor: FintechColors.primaryBlue,
        unselectedItemColor: FintechColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: FintechTypography.navLabel.copyWith(
          color: FintechColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: FintechTypography.navLabel.copyWith(
          color: FintechColors.textMuted,
        ),
      ),
      
      // Navigation Rail (for tablets/desktop)
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: FintechColors.cardBackground,
        selectedIconTheme: IconThemeData(color: FintechColors.primaryBlue),
        unselectedIconTheme: IconThemeData(color: FintechColors.textMuted),
        selectedLabelTextStyle: TextStyle(color: FintechColors.primaryBlue),
        unselectedLabelTextStyle: TextStyle(color: FintechColors.textMuted),
      ),
      
      // ============ OTHER COMPONENTS ============
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: FintechColors.dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // List Tiles
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: FintechColors.primaryBlue.withOpacity(0.1),
        iconColor: FintechColors.textSecondary,
        textColor: FintechColors.textPrimary,
        titleTextStyle: FintechTypography.bodyLarge.copyWith(
          color: FintechColors.textPrimary,
        ),
        subtitleTextStyle: FintechTypography.bodyMedium.copyWith(
          color: FintechColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: FintechColors.surfaceColor,
        selectedColor: FintechColors.primaryBlue,
        disabledColor: FintechColors.textMuted.withOpacity(0.3),
        deleteIconColor: FintechColors.textSecondary,
        labelStyle: FintechTypography.labelMedium.copyWith(
          color: FintechColors.textPrimary,
        ),
        secondaryLabelStyle: FintechTypography.labelMedium.copyWith(
          color: FintechColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return FintechColors.textPrimary;
          }
          return FintechColors.textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return FintechColors.primaryBlue;
          }
          return FintechColors.borderColor;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return FintechColors.primaryBlue;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(FintechColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return FintechColors.primaryBlue;
          }
          return FintechColors.borderColor;
        }),
      ),
      
      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: FintechColors.primaryBlue,
        inactiveTrackColor: FintechColors.borderColor,
        thumbColor: FintechColors.primaryBlue,
        overlayColor: FintechColors.primaryBlue,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FintechColors.primaryBlue,
        linearTrackColor: FintechColors.borderColor,
        circularTrackColor: FintechColors.borderColor,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: FintechColors.textSecondary,
        size: 24,
      ),
      
      primaryIconTheme: const IconThemeData(
        color: FintechColors.textPrimary,
        size: 24,
      ),
      
      // Text Theme (Material 3)
      textTheme: TextTheme(
        displayLarge: FintechTypography.hero.copyWith(color: FintechColors.textPrimary),
        displayMedium: FintechTypography.h1.copyWith(color: FintechColors.textPrimary),
        displaySmall: FintechTypography.h2.copyWith(color: FintechColors.textPrimary),
        headlineLarge: FintechTypography.h2.copyWith(color: FintechColors.textPrimary),
        headlineMedium: FintechTypography.h3.copyWith(color: FintechColors.textPrimary),
        headlineSmall: FintechTypography.h4.copyWith(color: FintechColors.textPrimary),
        titleLarge: FintechTypography.h4.copyWith(color: FintechColors.textPrimary),
        titleMedium: FintechTypography.h5.copyWith(color: FintechColors.textPrimary),
        titleSmall: FintechTypography.h6.copyWith(color: FintechColors.textPrimary),
        bodyLarge: FintechTypography.bodyLarge.copyWith(color: FintechColors.textPrimary),
        bodyMedium: FintechTypography.bodyMedium.copyWith(color: FintechColors.textSecondary),
        bodySmall: FintechTypography.bodySmall.copyWith(color: FintechColors.textMuted),
        labelLarge: FintechTypography.labelLarge.copyWith(color: FintechColors.textPrimary),
        labelMedium: FintechTypography.labelMedium.copyWith(color: FintechColors.textSecondary),
        labelSmall: FintechTypography.labelSmall.copyWith(color: FintechColors.textMuted),
      ),
      
      // Extensions
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }
  
  /// Light theme (optional, focusing on dark theme for now)
  static ThemeData get lightTheme {
    const lightSurfaceVariant = Color(0xFFF3F4F6);
    const lightOutline = Color(0xFFE5E7EB);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: FintechTypography.fontFamily,

      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: FintechColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: FintechColors.primaryPurple,
        onPrimaryContainer: Colors.white,

        secondary: FintechColors.accentGreen,
        onSecondary: Colors.white,
        secondaryContainer: FintechColors.successColor,
        onSecondaryContainer: Colors.white,

        tertiary: FintechColors.accentTeal,
        onTertiary: Colors.white,
        tertiaryContainer: FintechColors.infoColor,
        onTertiaryContainer: Colors.white,

        error: FintechColors.errorColor,
        onError: Colors.white,
        errorContainer: FintechColors.errorColor,
        onErrorContainer: Colors.white,

        background: FintechColors.lightBackground,
        onBackground: FintechColors.lightTextPrimary,
        surface: FintechColors.lightCardBackground,
        onSurface: FintechColors.lightTextPrimary,
        surfaceVariant: lightSurfaceVariant,
        onSurfaceVariant: FintechColors.lightTextSecondary,

        outline: lightOutline,
        outlineVariant: lightOutline,
        shadow: Color(0x14000000),
        scrim: Color(0x66000000),
      ),

      scaffoldBackgroundColor: FintechColors.lightBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: FintechColors.lightBackground,
        foregroundColor: FintechColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: FintechTypography.h4.copyWith(
          color: FintechColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: FintechColors.lightTextPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: FintechColors.lightTextPrimary,
          size: 24,
        ),
        centerTitle: false,
        titleSpacing: 20,
      ),

      cardTheme: CardThemeData(
        color: FintechColors.lightCardBackground,
        shadowColor: const Color(0x14000000),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FintechColors.primaryBlue,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: FintechTypography.buttonMedium,
          minimumSize: const Size(0, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FintechColors.primaryBlue,
          textStyle: FintechTypography.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 44),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FintechColors.lightTextPrimary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: lightOutline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: FintechTypography.buttonMedium,
          minimumSize: const Size(0, 48),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FintechColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FintechColors.errorColor, width: 2),
        ),
        labelStyle: FintechTypography.inputLabel.copyWith(
          color: FintechColors.lightTextSecondary,
        ),
        floatingLabelStyle: FintechTypography.inputLabel.copyWith(
          color: FintechColors.primaryBlue,
        ),
        hintStyle: FintechTypography.inputHint.copyWith(
          color: FintechColors.lightTextSecondary,
        ),
        helperStyle: FintechTypography.caption.copyWith(
          color: FintechColors.lightTextSecondary,
        ),
        errorStyle: FintechTypography.caption.copyWith(
          color: FintechColors.errorColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: false,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FintechColors.lightCardBackground,
        selectedItemColor: FintechColors.primaryBlue,
        unselectedItemColor: FintechColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: FintechTypography.navLabel.copyWith(
          color: FintechColors.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: FintechTypography.navLabel.copyWith(
          color: FintechColors.lightTextSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: lightOutline,
        thickness: 1,
        space: 1,
      ),

      textTheme: TextTheme(
        displayLarge: FintechTypography.hero.copyWith(color: FintechColors.lightTextPrimary),
        displayMedium: FintechTypography.h1.copyWith(color: FintechColors.lightTextPrimary),
        displaySmall: FintechTypography.h2.copyWith(color: FintechColors.lightTextPrimary),
        headlineLarge: FintechTypography.h2.copyWith(color: FintechColors.lightTextPrimary),
        headlineMedium: FintechTypography.h3.copyWith(color: FintechColors.lightTextPrimary),
        headlineSmall: FintechTypography.h4.copyWith(color: FintechColors.lightTextPrimary),
        titleLarge: FintechTypography.h4.copyWith(color: FintechColors.lightTextPrimary),
        titleMedium: FintechTypography.h5.copyWith(color: FintechColors.lightTextPrimary),
        titleSmall: FintechTypography.h6.copyWith(color: FintechColors.lightTextPrimary),
        bodyLarge: FintechTypography.bodyLarge.copyWith(color: FintechColors.lightTextPrimary),
        bodyMedium: FintechTypography.bodyMedium.copyWith(color: FintechColors.lightTextSecondary),
        bodySmall: FintechTypography.bodySmall.copyWith(color: FintechColors.lightTextSecondary),
        labelLarge: FintechTypography.labelLarge.copyWith(color: FintechColors.lightTextPrimary),
        labelMedium: FintechTypography.labelMedium.copyWith(color: FintechColors.lightTextSecondary),
        labelSmall: FintechTypography.labelSmall.copyWith(color: FintechColors.lightTextSecondary),
      ),
    );
  }
}