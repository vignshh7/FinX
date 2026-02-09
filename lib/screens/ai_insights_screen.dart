import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/premium_cards.dart';
import '../core/widgets/loading_skeleton.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _insights;
  List<Map<String, dynamic>> _anomalies = [];
  Map<String, dynamic>? _monthComparison;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Simulate insights generation
      await Future.delayed(const Duration(seconds: 1));

      // Generate insights from expense data
      _generateInsights(expenseProvider);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateInsights(ExpenseProvider provider) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    // Filter expenses by month
    final currentMonthExpenses = provider.expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();
    final lastMonthExpenses = provider.expenses
        .where((e) => e.date.month == lastMonth.month && e.date.year == lastMonth.year)
        .toList();

    // Calculate totals
    final currentTotal = currentMonthExpenses.fold<double>(
        0, (sum, e) => sum + e.amount);
    final lastTotal = lastMonthExpenses.fold<double>(
        0, (sum, e) => sum + e.amount);

    final changePct = lastTotal > 0 
        ? ((currentTotal - lastTotal) / lastTotal) * 100 
        : 0.0;

    // Month comparison
    _monthComparison = {
      'current_total': currentTotal,
      'last_total': lastTotal,
      'change_percentage': changePct,
      'change_amount': currentTotal - lastTotal,
    };

    // Detect anomalies (unusually high spending)
    _anomalies = [];
    final categoryTotals = provider.categoryTotals;
    categoryTotals.forEach((category, amount) {
      final avgForCategory = amount / currentMonthExpenses
          .where((e) => e.category == category)
          .length;
      
      if (avgForCategory > 100) { // Simple threshold
        _anomalies.add({
          'category': category,
          'amount': amount,
          'message': 'Higher than usual spending in $category',
          'severity': 'warning',
        });
      }
    });

    // Generate natural language insights
    _insights = {
      'summary': _generateSummaryInsight(changePct, currentTotal, lastTotal),
      'top_category': _getTopCategory(categoryTotals),
      'recommendation': _generateRecommendation(changePct, categoryTotals),
      'trend': changePct > 0 ? 'increasing' : 'decreasing',
    };
  }

  String _generateSummaryInsight(double changePct, double current, double last) {
    if (changePct > 10) {
      return 'Your spending increased by ${changePct.toStringAsFixed(1)}% this month. Consider reviewing your budget.';
    } else if (changePct < -10) {
      return 'Great job! You spent ${changePct.abs().toStringAsFixed(1)}% less this month.';
    } else {
      return 'Your spending is consistent with last month.';
    }
  }

  String _getTopCategory(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return 'No data';
    
    final topEntry = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return topEntry.key;
  }

  String _generateRecommendation(double changePct, Map<String, double> categoryTotals) {
    if (changePct > 15) {
      final topCategory = _getTopCategory(categoryTotals);
      return 'Try setting a specific budget for $topCategory to control spending.';
    } else if (changePct < -15) {
      return 'Your spending habits are improving! Keep up the good work.';
    } else {
      return 'Maintain your current spending patterns and track regularly.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currency);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
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
                'AI Insights',
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
                    colors: AppColors.accentGradient,
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _loadInsights();
                },
              ),
            ],
          ),

          // Content
          _isLoading
              ? _buildLoadingState()
              : _buildContent(currencyFormat),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const CardLoadingSkeleton(height: 150),
          SizedBox(height: AppSpacing.md),
          const CardLoadingSkeleton(height: 200),
          SizedBox(height: AppSpacing.md),
          const CardLoadingSkeleton(height: 180),
        ]),
      ),
    );
  }

  Widget _buildContent(NumberFormat format) {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // AI Summary Card
          if (_insights != null) ...[
            _buildAISummaryCard(_insights!, format)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
            SizedBox(height: AppSpacing.md),
          ],

          // Month Comparison
          if (_monthComparison != null) ...[
            _buildMonthComparisonCard(_monthComparison!, format)
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
            SizedBox(height: AppSpacing.md),
          ],

          // Anomalies/Alerts
          if (_anomalies.isNotEmpty) ...[
            Text('Spending Alerts', style: AppTypography.h6)
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms),
            SizedBox(height: AppSpacing.sm),
            ..._anomalies.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildAnomalyCard(entry.value, format)
                    .animate(delay: (200 + entry.key * 50).ms)
                    .fadeIn()
                    .slideX(begin: -0.1, end: 0),
              );
            }),
            SizedBox(height: AppSpacing.md),
          ],

          // Recommendations
          if (_insights != null) ...[
            Text('AI Recommendation', style: AppTypography.h6)
                .animate()
                .fadeIn(duration: 300.ms, delay: 400.ms),
            SizedBox(height: AppSpacing.sm),
            _buildRecommendationCard(_insights!)
                .animate()
                .fadeIn(duration: 300.ms, delay: 450.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ]),
      ),
    );
  }

  Widget _buildAISummaryCard(Map<String, dynamic> insights, NumberFormat format) {
    final trend = insights['trend'] as String;
    final isIncreasing = trend == 'increasing';

    return GradientCard(
      gradientColors: isIncreasing 
          ? AppColors.warningGradient 
          : AppColors.successGradient,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.auto_awesome,
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
                  'AI Analysis',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  insights['summary'],
                  style: AppTypography.bodyLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthComparisonCard(Map<String, dynamic> comparison, NumberFormat format) {
    final currentTotal = comparison['current_total'] as double;
    final lastTotal = comparison['last_total'] as double;
    final changePct = comparison['change_percentage'] as double;
    final changeAmount = comparison['change_amount'] as double;
    final isIncrease = changePct > 0;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Month Comparison', style: AppTypography.h6),
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                color: isIncrease ? AppColors.error : AppColors.success,
                size: AppSpacing.iconLg,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      format.format(currentTotal),
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Month',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      format.format(lastTotal),
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isIncrease 
                  ? AppColors.errorLight 
                  : AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncrease ? AppColors.error : AppColors.success,
                  size: 16,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  '${changePct.abs().toStringAsFixed(1)}% (${format.format(changeAmount.abs())})',
                  style: AppTypography.bodyLg.copyWith(
                    color: isIncrease ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> anomaly, NumberFormat format) {
    return InfoCard(
      icon: Icons.warning_rounded,
      iconColor: AppColors.warning,
      title: anomaly['message'],
      subtitle: 'Amount: ${format.format(anomaly['amount'])}',
      backgroundColor: AppColors.warningLight,
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> insights) {
    return GradientCard(
      gradientColors: AppColors.infoGradient,
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_rounded,
            size: AppSpacing.iconXl,
            color: Colors.white,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  insights['recommendation'],
                  style: AppTypography.bodyLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
