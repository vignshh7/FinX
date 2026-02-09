import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/premium_cards.dart';
import '../core/widgets/premium_buttons.dart';
import '../core/widgets/loading_skeleton.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';

class SubscriptionIntelligenceScreen extends StatefulWidget {
  const SubscriptionIntelligenceScreen({super.key});

  @override
  State<SubscriptionIntelligenceScreen> createState() =>
      _SubscriptionIntelligenceScreenState();
}

class _SubscriptionIntelligenceScreenState
    extends State<SubscriptionIntelligenceScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.fetchSubscriptions();
  }

  Map<String, dynamic> _analyzeSubscriptions(
      SubscriptionProvider provider) {
    final now = DateTime.now();
    final subscriptions = provider.subscriptions;

    // Renewal predictions
    final upcomingRenewals = subscriptions.where((sub) {
      final nextBilling = sub.renewalDate;
      return nextBilling.difference(now).inDays <= 7;
    }).toList();

    // Unused detection (simple heuristic)
    final unusedSubs = subscriptions.where((sub) {
      // Assume inactive if last renewal was more than 90 days ago
      return now.difference(sub.renewalDate).inDays > 90;
    }).toList();

    // Cost analysis
    final totalMonthly = subscriptions.fold<double>(
        0, (sum, sub) => sum + sub.amount);

    return {
      'upcoming_renewals': upcomingRenewals,
      'unused_subscriptions': unusedSubs,
      'total_monthly': totalMonthly,
      'total_yearly': totalMonthly * 12,
      'optimization_potential':
          unusedSubs.fold<double>(0, (sum, sub) => sum + sub.amount),
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat =
        NumberFormat.currency(symbol: themeProvider.currency);

    final analysis = _analyzeSubscriptions(provider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: AppSpacing.lg + 40,
                bottom: AppSpacing.md,
              ),
              title: Text(
                'Subscription AI',
                style: AppTypography.h5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.primaryGradient,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),

          provider.isLoading
              ? _buildLoadingState()
              : _buildContent(provider, analysis, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const CardLoadingSkeleton(height: 140),
          SizedBox(height: AppSpacing.md),
          const CardLoadingSkeleton(height: 120),
        ]),
      ),
    );
  }

  Widget _buildContent(
    SubscriptionProvider provider,
    Map<String, dynamic> analysis,
    NumberFormat format,
  ) {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Cost Summary
          _buildCostSummary(analysis, format)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),

          SizedBox(height: AppSpacing.md),

          // Optimization Card
          if (analysis['optimization_potential'] > 0) ...[
            _buildOptimizationCard(analysis, format)
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
            SizedBox(height: AppSpacing.md),
          ],

          // Upcoming Renewals
          if ((analysis['upcoming_renewals'] as List).isNotEmpty) ...[
            Text('Upcoming Renewals', style: AppTypography.h6)
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms),
            SizedBox(height: AppSpacing.sm),
            ...(analysis['upcoming_renewals'] as List).asMap().entries.map(
              (entry) {
                final sub = entry.value;
                final daysUntil =
                  sub.renewalDate.difference(DateTime.now()).inDays;

                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InfoCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.warning,
                    title: '${sub.name} renewing in $daysUntil days',
                    subtitle: format.format(sub.amount),
                    backgroundColor: AppColors.warningLight,
                  )
                      .animate(delay: (200 + entry.key * 50).ms)
                      .fadeIn()
                      .slideX(begin: -0.1, end: 0),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
          ],

          // Unused Subscriptions
          if ((analysis['unused_subscriptions'] as List).isNotEmpty) ...[
            Text('Potentially Unused', style: AppTypography.h6)
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms),
            SizedBox(height: AppSpacing.sm),
            ...(analysis['unused_subscriptions'] as List)
                .asMap()
                .entries
                .map(
              (entry) {
                final sub = entry.value;

                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PremiumCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.name,
                                style: AppTypography.bodyLg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Save ${format.format(sub.amount)}/month',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PremiumOutlinedButton(
                          text: 'Review',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                  )
                      .animate(delay: (300 + entry.key * 50).ms)
                      .fadeIn()
                      .slideX(begin: 0.1, end: 0),
                );
              },
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildCostSummary(
      Map<String, dynamic> analysis, NumberFormat format) {
    return GradientCard(
      gradientColors: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Subscription Cost',
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            format.format(analysis['total_monthly']),
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Per month • ${format.format(analysis['total_yearly'])} yearly',
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationCard(
      Map<String, dynamic> analysis, NumberFormat format) {
    final potential = analysis['optimization_potential'];

    return GradientCard(
      gradientColors: AppColors.successGradient,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.savings_rounded,
              size: AppSpacing.iconXl,
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimization Potential',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  format.format(potential),
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Potential monthly savings',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
