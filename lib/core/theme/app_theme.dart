import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Premium app theme following Material 3 guidelines
/// Inspired by: Google Pay, Cred, Apple Wallet, Mint
class AppTheme {
  // Private constructor
  AppTheme._();

  // ============ LIGHT THEME ============
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryIndigo,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryIndigoLight,
      onPrimaryContainer: AppColors.primaryIndigoDark,
      
      secondary: AppColors.accentEmerald,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentEmeraldLight,
      onSecondaryContainer: AppColors.accentEmeraldDark,
      
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.infoLight,
      onTertiaryContainer: AppColors.infoDark,
      
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.errorDark,
      
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      
      shadow: Colors.black.withOpacity(0.1),
      scrim: Colors.black.withOpacity(0.5),
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    // Typography
    textTheme: AppTypography.getTextTheme(isDark: false).apply(
      bodyColor: AppColors.textPrimaryLight,
      displayColor: AppColors.textPrimaryLight,
    ),
    
    // App bar
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSpacing.iconMd,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      elevation: AppSpacing.elevationSm,
      color: AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.textTertiaryLight,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonLarge,
      ),
    ),
    
    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryIndigo,
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryIndigo,
        side: const BorderSide(color: AppColors.primaryIndigo, width: 1.5),
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonLarge,
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.primaryIndigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiaryLight,
      ),
      errorStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.error,
      ),
    ),
    
    // Floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: AppSpacing.elevationMd,
      backgroundColor: AppColors.primaryIndigo,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    
    // Bottom navigation bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: AppSpacing.elevationLg,
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryIndigo,
      unselectedItemColor: AppColors.textSecondaryLight,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 1,
      space: 1,
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundLight,
      deleteIconColor: AppColors.textSecondaryLight,
      disabledColor: AppColors.textTertiaryLight,
      selectedColor: AppColors.primaryIndigoLight,
      secondarySelectedColor: AppColors.accentEmeraldLight,
      padding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelStyle: AppTypography.chip,
      secondaryLabelStyle: AppTypography.chip,
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
      ),
    ),
    
    // Dialog
    dialogTheme: DialogThemeData(
      elevation: AppSpacing.elevationXl,
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
      ),
    ),
    
    // Bottom sheet
    bottomSheetTheme: BottomSheetThemeData(
      elevation: AppSpacing.elevationXl,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
    ),
    
    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryIndigo,
    ),
    
    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.textPrimaryLight,
      size: AppSpacing.iconMd,
    ),
  );
  
  // ============ DARK THEME ============
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryIndigoLight,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.primaryIndigoDark,
      onPrimaryContainer: AppColors.primaryIndigoLight,
      
      secondary: AppColors.accentEmeraldLight,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: AppColors.accentEmeraldDark,
      onSecondaryContainer: AppColors.accentEmeraldLight,
      
      tertiary: AppColors.infoLight,
      onTertiary: AppColors.backgroundDark,
      tertiaryContainer: AppColors.infoDark,
      onTertiaryContainer: AppColors.infoLight,
      
      error: AppColors.errorLight,
      onError: AppColors.backgroundDark,
      errorContainer: AppColors.errorDark,
      onErrorContainer: AppColors.errorLight,
      
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      
      shadow: Colors.black.withOpacity(0.3),
      scrim: Colors.black.withOpacity(0.7),
    ),
    
    // Scaffold
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    // Typography
    textTheme: AppTypography.getTextTheme(isDark: true).apply(
      bodyColor: AppColors.textPrimaryDark,
      displayColor: AppColors.textPrimaryDark,
    ),
    
    // App bar
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSpacing.iconMd,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      elevation: AppSpacing.elevationSm,
      color: AppColors.cardDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryIndigoLight,
        foregroundColor: AppColors.backgroundDark,
        disabledBackgroundColor: AppColors.textTertiaryDark,
        disabledForegroundColor: AppColors.backgroundDark,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonLarge,
      ),
    ),
    
    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryIndigoLight,
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryIndigoLight,
        side: const BorderSide(color: AppColors.primaryIndigoLight, width: 1.5),
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
        padding: AppSpacing.horizontalPadding(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonLarge,
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.primaryIndigoLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiaryDark,
      ),
      errorStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.errorLight,
      ),
    ),
    
    // Floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: AppSpacing.elevationMd,
      backgroundColor: AppColors.primaryIndigoLight,
      foregroundColor: AppColors.backgroundDark,
      shape: CircleBorder(),
    ),
    
    // Bottom navigation bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: AppSpacing.elevationLg,
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryIndigoLight,
      unselectedItemColor: AppColors.textSecondaryDark,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
      space: 1,
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceDark,
      deleteIconColor: AppColors.textSecondaryDark,
      disabledColor: AppColors.textTertiaryDark,
      selectedColor: AppColors.primaryIndigoDark,
      secondarySelectedColor: AppColors.accentEmeraldDark,
      padding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelStyle: AppTypography.chip,
      secondaryLabelStyle: AppTypography.chip,
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
      ),
    ),
    
    // Dialog
    dialogTheme: DialogThemeData(
      elevation: AppSpacing.elevationXl,
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryDark,
      ),
    ),
    
    // Bottom sheet
    bottomSheetTheme: BottomSheetThemeData(
      elevation: AppSpacing.elevationXl,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
    ),
    
    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryIndigoLight,
    ),
    
    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.textPrimaryDark,
      size: AppSpacing.iconMd,
    ),
  );
}
