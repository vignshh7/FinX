import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Premium loading skeleton (no spinners!)
/// Animated shimmer effect for smooth loading states
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.dividerLight,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
      ),
      child: const _ShimmerEffect(),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      AppColors.surfaceDark,
                      AppColors.cardDark,
                      AppColors.surfaceDark,
                    ]
                  : [
                      AppColors.dividerLight,
                      AppColors.backgroundLight,
                      AppColors.dividerLight,
                    ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// List loading skeleton
class ListLoadingSkeleton extends StatelessWidget {
  final int itemCount;

  const ListLoadingSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screenEdgePadding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => AppSpacing.vSpaceMd,
      itemBuilder: (context, index) {
        return Container(
          padding: AppSpacing.cardInnerPadding,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Row(
            children: [
              LoadingSkeleton(
                width: AppSpacing.iconLg,
                height: AppSpacing.iconLg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              AppSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(
                      width: double.infinity,
                      height: 16,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    AppSpacing.vSpaceSm,
                    LoadingSkeleton(
                      width: 120,
                      height: 12,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ],
                ),
              ),
              AppSpacing.hSpaceMd,
              LoadingSkeleton(
                width: 60,
                height: 20,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card loading skeleton
class CardLoadingSkeleton extends StatelessWidget {
  final double? height;
  
  const CardLoadingSkeleton({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: AppSpacing.cardInnerPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
            width: 100,
            height: 16,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          AppSpacing.vSpaceLg,
          LoadingSkeleton(
            width: double.infinity,
            height: 100,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          AppSpacing.vSpaceMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LoadingSkeleton(
                width: 80,
                height: 14,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              LoadingSkeleton(
                width: 60,
                height: 14,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
