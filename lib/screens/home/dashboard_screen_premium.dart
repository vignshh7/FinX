import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/premium_cards.dart';
import '../../core/widgets/premium_buttons.dart';
import '../../core/widgets/premium_indicators.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../receipt_scanner_screen_premium.dart';
import '../expense_history_screen.dart';

class DashboardScreenPremium extends StatefulWidget {
  const DashboardScreenPremium({super.key});

  @override
  State<DashboardScreenPremium> createState() => _DashboardScreenPremiumState();
}

class _DashboardScreenPremiumState extends State<DashboardScreenPremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    await Future.wait([
      expenseProvider.fetchExpenses(),
      expenseProvider.fetchPrediction(),
      expenseProvider.fetchAlerts(),
    ]);
  }

  void _navigateToScanner() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScannerScreenPremium()),
    );
  }

  void _navigateToHistory() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar
          _buildSliverAppBar(context),

          // Content
          SliverToRefreshIndicator(
            onRefresh: _loadData,
            child: expenseProvider.isLoading
                ? _buildLoadingState()
                : _buildContent(expenseProvider, themeProvider),
          ),
        ],
      ),
      floatingActionButton: PremiumFAB(
        icon: Icons.camera_alt_rounded,
        label: 'Scan Receipt',
        onPressed: _navigateToScanner,
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        title: Text(
          'Dashboard',
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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: AppTypography.bodyMd.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const CardLoadingSkeleton(height: 180),
          SizedBox(height: AppSpacing.md),
          const CardLoadingSkeleton(height: 120),
          SizedBox(height: AppSpacing.md),
          const CardLoadingSkeleton(height: 300),
          SizedBox(height: AppSpacing.md),
          const ListLoadingSkeleton(itemCount: 5),
        ]),
      ),
    );
  }

  Widget _buildContent(ExpenseProvider provider, ThemeProvider themeProvider) {
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currency);

    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Monthly Summary Card
          _buildMonthlySummaryCard(provider, themeProvider, currencyFormat)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),

          SizedBox(height: AppSpacing.md),

          // Alerts
          if (provider.alerts.isNotEmpty) ...[
            _buildAlertsSection(provider)
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
            SizedBox(height: AppSpacing.md),
          ],

          // AI Prediction
          if (provider.prediction != null) ...[
            _buildAIPredictionCard(provider, currencyFormat)
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0),
            SizedBox(height: AppSpacing.md),
          ],

          // Quick Stats
          _buildQuickStats(provider, currencyFormat)
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0),

          SizedBox(height: AppSpacing.lg),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending by Category', style: AppTypography.h6),
              PremiumTextButton(
                text: 'View All',
                onPressed: _navigateToHistory,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms),

          SizedBox(height: AppSpacing.md),

          // Category Chart
          _buildCategoryChart(provider)
              .animate()
              .fadeIn(duration: 300.ms, delay: 500.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          SizedBox(height: AppSpacing.lg),

          // Category Breakdown
          _buildCategoryBreakdown(provider, currencyFormat),

          SizedBox(height: AppSpacing.xxxl * 2), // Space for FAB
        ]),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
    ExpenseProvider provider,
    ThemeProvider themeProvider,
    NumberFormat format,
  ) {
    final monthlyTotal = provider.monthlyTotal;
    final budget = themeProvider.monthlyBudget;
    final percentage = budget > 0 ? (monthlyTotal / budget) * 100 : 0.0;
    final remaining = budget - monthlyTotal;
    final isOverBudget = percentage > 100;

    return GradientCard(
      gradientColors: isOverBudget
          ? AppColors.errorGradient
          : AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Spending',
                style: AppTypography.h6.copyWith(color: Colors.white),
              ),
              Icon(
                isOverBudget ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: AppSpacing.iconLg,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            format.format(monthlyTotal),
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (budget > 0) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% of budget',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  isOverBudget
                      ? 'Over by ${format.format(remaining.abs())}'
                      : '${format.format(remaining)} left',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsSection(ExpenseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.warning, size: 20),
            SizedBox(width: AppSpacing.xs),
            Text('Alerts', style: AppTypography.h6),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        ...provider.alerts.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: InfoCard(
              icon: Icons.warning_rounded,
              iconColor: AppColors.warning,
              title: entry.value['message'] ?? 'Alert',
              subtitle: 'Review your spending to stay on track',
              backgroundColor: AppColors.warningLight,
            ).animate(delay: (entry.key * 50).ms).fadeIn().slideX(begin: -0.1, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildAIPredictionCard(ExpenseProvider provider, NumberFormat format) {
    final prediction = provider.prediction!;
    final predictedAmount = prediction['predicted_amount'] ?? 0.0;
    final confidence = prediction['confidence'] ?? 0.0;

    return GradientCard(
      gradientColors: AppColors.accentGradient,
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
                  'AI Prediction',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  format.format(predictedAmount),
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Expected next month',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ConfidenceIndicator(
            confidence: confidence,
            showPercentage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ExpenseProvider provider, NumberFormat format) {
    final expenses = provider.expenses;
    final avgDaily = provider.monthlyTotal / DateTime.now().day;
    final transactionCount = expenses.length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: transactionCount.toString(),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Daily Average',
            value: format.format(avgDaily),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(ExpenseProvider provider) {
    final categoryTotals = provider.categoryTotals;

    if (categoryTotals.isEmpty) {
      return EmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No spending data',
        subtitle: 'Start by scanning a receipt',
        actionText: 'Scan Now',
        onAction: _navigateToScanner,
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();
    final total = topCategories.fold<double>(0, (sum, entry) => sum + entry.value);

    return PremiumCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: topCategories.asMap().entries.map((entry) {
                  final category = entry.value.key;
                  final amount = entry.value.value;
                  final percentage = (amount / total) * 100;

                  return PieChartSectionData(
                    color: AppColors.getCategoryColor(category),
                    value: amount,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: AppTypography.bodyMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider, NumberFormat format) {
    final categoryTotals = provider.categoryTotals;

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Breakdown', style: AppTypography.h6),
        SizedBox(height: AppSpacing.md),
        ...sortedCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value.key;
          final amount = entry.value.value;

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getCategoryColor(category),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: AppTypography.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${provider.expenses.where((e) => e.category == category).length} transactions',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AmountDisplay(
                    amount: amount,
                    style: AppTypography.h6,
                  ),
                ],
              ),
            ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0),
          );
        }),
      ],
    );
  }
}

class SliverToRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const SliverToRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
