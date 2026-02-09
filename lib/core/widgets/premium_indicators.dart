import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Category chip with color indicator
class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getCategoryColor(category);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.symmetricPadding(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hSpaceXs,
            Text(
              category,
              style: AppTypography.chip.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confidence indicator
class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final bool showPercentage;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getConfidenceColor(confidence);
    final percentage = (confidence * 100).toInt();
    
    return Container(
      padding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence >= 0.7
                ? Icons.check_circle
                : confidence >= 0.4
                    ? Icons.info
                    : Icons.warning,
            size: 14,
            color: color,
          ),
          if (showPercentage) ...[
            AppSpacing.hSpaceXs,
            Text(
              '$percentage%',
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Amount display widget
class AmountDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.currency = '\$',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    
    return Text(
      '$currency${amount.abs().toStringAsFixed(2)}',
      style: (style ?? AppTypography.amountSmall).copyWith(color: color),
    );
  }
}

/// Trend indicator
class TrendIndicator extends StatelessWidget {
  final double percentage;
  final String? label;

  const TrendIndicator({
    super.key,
    required this.percentage,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage > 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    
    return Container(
      padding: AppSpacing.symmetricPadding(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: color,
          ),
          AppSpacing.hSpaceXs,
          Text(
            '${percentage.abs().toStringAsFixed(1)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (label != null) ...[
            AppSpacing.hSpaceXs,
            Text(
              label!,
              style: AppTypography.labelSmall.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: AppSpacing.screenEdgePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.primaryIndigoLight
                        : AppColors.primaryIndigo)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: isDark
                    ? AppColors.primaryIndigoLight
                    : AppColors.primaryIndigo,
              ),
            ),
            AppSpacing.vSpaceXl,
            Text(
              title,
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppSpacing.vSpaceSm,
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              AppSpacing.vSpaceXl,
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
