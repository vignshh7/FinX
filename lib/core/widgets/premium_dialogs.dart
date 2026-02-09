import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Premium bottom sheet
class PremiumBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetContent(
        title: title,
        child: child,
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final String? title;
  final Widget child;

  const _BottomSheetContent({
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXxl),
          topRight: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            AppSpacing.vSpaceSm,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            if (title != null) ...[
              AppSpacing.vSpaceLg,
              Padding(
                padding: AppSpacing.screenEdgePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title!,
                      style: AppTypography.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
            
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.screenEdgePadding,
                child: child,
              ),
            ),
            
            AppSpacing.vSpaceLg,
          ],
        ),
      ),
    );
  }
}

/// Premium dialog
class PremiumDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    bool isDangerous = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTypography.headlineSmall),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onConfirm?.call();
                Navigator.pop(context, true);
              },
              style: isDangerous
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    )
                  : null,
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  static Future<T?> custom<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: AppSpacing.allPadding(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(title, style: AppTypography.headlineSmall),
                AppSpacing.vSpaceLg,
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Success/Error snackbar
class PremiumSnackBar {
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            AppSpacing.hSpaceMd,
            Expanded(
              child: Text(message, style: AppTypography.bodyMedium),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            AppSpacing.hSpaceMd,
            Expanded(
              child: Text(message, style: AppTypography.bodyMedium),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            AppSpacing.hSpaceMd,
            Expanded(
              child: Text(message, style: AppTypography.bodyMedium),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
