import 'package:flutter/material.dart';
import '../theme/fintech_colors.dart';
import '../theme/fintech_typography.dart';

/// Modern fintech UI components for FinX app
class FintechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  final Border? border;

  const FintechCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 2,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget cardChild = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (backgroundColor ?? theme.cardColor) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (margin != null) {
      cardChild = Container(
        margin: margin,
        child: cardChild,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardChild,
      );
    }

    return cardChild;
  }
}

/// Quick action button with icon and label
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColorDefault = textColor ?? theme.colorScheme.onSurface;
    
    return FintechCard(
      onTap: onTap,
      gradient: gradient,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (iconColor ?? FintechColors.primaryBlue).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 26,
              color: iconColor ?? FintechColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              label,
              style: FintechTypography.labelMedium.copyWith(
                color: textColorDefault,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature card for main app features
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? iconColor;
  final Widget? trailing;
  final bool isComingSoon;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
    this.iconColor,
    this.trailing,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.6);
    
    return FintechCard(
      onTap: isComingSoon ? null : onTap,
      gradient: gradient,
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? FintechColors.primaryBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? FintechColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: FintechTypography.h6.copyWith(
                        color: textColor,
                      ),
                    ),
                    if (isComingSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FintechColors.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Soon',
                          style: FintechTypography.labelSmall.copyWith(
                            color: FintechColors.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: FintechTypography.bodySmall.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Trailing
          if (trailing != null)
            trailing!
          else
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isComingSoon ? theme.colorScheme.onSurface.withOpacity(0.3) : secondaryTextColor,
            ),
        ],
      ),
    );
  }
}

/// Stats card for displaying financial metrics
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? valueColor;
  final Color? iconColor;
  final bool showTrend;
  final double? trendValue;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.iconColor,
    this.showTrend = false,
    this.trendValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.6);
    
    Color getTrendColor() {
      if (trendValue == null) return secondaryTextColor;
      return trendValue! >= 0 ? FintechColors.successColor : FintechColors.errorColor;
    }

    IconData getTrendIcon() {
      if (trendValue == null) return Icons.trending_flat;
      return trendValue! >= 0 ? Icons.trending_up : Icons.trending_down;
    }

    return FintechCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: FintechTypography.labelMedium.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? secondaryTextColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Value
          Text(
            value,
            style: FintechTypography.currencyMedium.copyWith(
              color: valueColor ?? textColor,
            ),
          ),
          
          if (subtitle != null || showTrend) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: FintechTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                if (showTrend && trendValue != null) ...[
                  Icon(
                    getTrendIcon(),
                    size: 16,
                    color: getTrendColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trendValue!.abs().toStringAsFixed(1)}%',
                    style: FintechTypography.labelSmall.copyWith(
                      color: getTrendColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: FintechTypography.h5.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: FintechTypography.labelMedium.copyWith(
                      color: FintechColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      actionIcon,
                      size: 16,
                      color: FintechColors.primaryBlue,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading shimmer effect
class ShimmerCard extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                FintechColors.surfaceColor,
                FintechColors.cardBackground,
                FintechColors.surfaceColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value * 3.14159),
            ),
          ),
        );
      },
    );
  }
}