import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';

class ModernAIInsightsScreen extends StatefulWidget {
  const ModernAIInsightsScreen({super.key});

  @override
  State<ModernAIInsightsScreen> createState() => _ModernAIInsightsScreenState();
}

class _ModernAIInsightsScreenState extends State<ModernAIInsightsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadAIInsights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAIInsights() async {
    setState(() => _isLoading = true);
    
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Fetch all AI-related data
      await Future.wait([
        expenseProvider.fetchExpenses(),
        expenseProvider.fetchPrediction(),
        expenseProvider.fetchAlerts(),
      ]);
      
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading insights: ${e.toString()}'),
            backgroundColor: FintechColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    return Scaffold(
      backgroundColor: isDark ? FintechColors.darkBackground : FintechColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadAIInsights,
                color: FintechColors.primaryColor,
                child: Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, _) {
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildAppBar(isDark),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildPredictionCard(expenseProvider, isDark),
                              const SizedBox(height: 20),
                              _buildAlertsSection(expenseProvider, isDark),
                              const SizedBox(height: 20),
                              _buildSpendingAnalysis(expenseProvider, isDark),
                              const SizedBox(height: 20),
                              _buildCategoryBreakdown(expenseProvider, isDark),
                              const SizedBox(height: 20),
                              _buildRecommendations(expenseProvider, isDark),
                              SizedBox(height: bottomPadding + 100),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: FintechColors.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your spending patterns...',
            style: FintechTypography.bodyMedium.copyWith(
              color: FintechColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? FintechColors.darkSurface : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'AI Insights',
          style: FintechTypography.h4.copyWith(
            color: isDark ? FintechColors.darkText : FintechColors.lightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? FintechColors.darkText : FintechColors.lightText,
          ),
          onPressed: _loadAIInsights,
        ),
      ],
    );
  }

  Widget _buildPredictionCard(ExpenseProvider provider, bool isDark) {
    final prediction = provider.prediction;
    if (prediction == null) {
      return _buildEmptyCard(
        'No Predictions Available',
        'Spend more to get AI-powered predictions',
        Icons.lightbulb_outline,
        isDark,
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;

    final nextMonthPrediction = prediction['next_month_prediction'] ?? 0.0;
    final confidence = prediction['confidence'] ?? 0.0;
    final trend = prediction['trend'] ?? 'stable';
    
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: trend == 'increasing'
                ? [FintechColors.errorColor.withOpacity(0.8), FintechColors.errorColor]
                : trend == 'decreasing'
                    ? [FintechColors.successColor.withOpacity(0.8), FintechColors.successColor]
                    : [FintechColors.infoColor.withOpacity(0.8), FintechColors.infoColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: FintechColors.primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_graph,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Forecast',
                        style: FintechTypography.h6.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}% confidence',
                        style: FintechTypography.caption.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Next Month Prediction',
              style: FintechTypography.caption.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$currencySymbol${nextMonthPrediction.toStringAsFixed(2)}',
              style: FintechTypography.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trend == 'increasing'
                        ? Icons.trending_up
                        : trend == 'decreasing'
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trend.toUpperCase(),
                    style: FintechTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(ExpenseProvider provider, bool isDark) {
    final alerts = provider.alerts;
    
    if (alerts.isEmpty) {
      return _buildEmptyCard(
        'No Alerts',
        'You\'re doing great! No spending alerts',
        Icons.check_circle_outline,
        isDark,
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? FintechColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: FintechColors.warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Alerts',
                    style: FintechTypography.h6.copyWith(
                      color: isDark ? FintechColors.darkText : FintechColors.lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FintechColors.warningColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: FintechTypography.caption.copyWith(
                        color: FintechColors.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertItem(alert, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(dynamic alert, bool isDark) {
    final type = alert['type'] ?? 'info';
    final message = alert['message'] ?? 'No message';
    final category = alert['category'];
    
    IconData icon;
    Color color;
    
    switch (type) {
      case 'warning':
        icon = Icons.warning_rounded;
        color = FintechColors.warningColor;
        break;
      case 'critical':
        icon = Icons.error_rounded;
        color = FintechColors.errorColor;
        break;
      default:
        icon = Icons.info_rounded;
        color = FintechColors.infoColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      category,
                      style: FintechTypography.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  message,
                  style: FintechTypography.bodySmall.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingAnalysis(ExpenseProvider provider, bool isDark) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    final currentMonthExpenses = provider.expenses
        .where((e) => e.date.isAfter(currentMonth))
        .toList();
    final lastMonthExpenses = provider.expenses
        .where((e) => e.date.isAfter(lastMonth) && e.date.isBefore(currentMonth))
        .toList();

    final currentTotal = currentMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final lastTotal = lastMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    
    final change = currentTotal - lastTotal;
    final changePercent = lastTotal > 0 ? (change / lastTotal) * 100 : 0.0;
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? FintechColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: FintechColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Spending Analysis',
                  style: FintechTypography.h6.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisCard(
                    'This Month',
                    '$currencySymbol${currentTotal.toStringAsFixed(2)}',
                    currentMonthExpenses.length.toString(),
                    'transactions',
                    FintechColors.primaryColor,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalysisCard(
                    'Last Month',
                    '$currencySymbol${lastTotal.toStringAsFixed(2)}',
                    lastMonthExpenses.length.toString(),
                    'transactions',
                    FintechColors.secondaryColor,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: changePercent >= 0
                    ? FintechColors.errorColor.withOpacity(0.1)
                    : FintechColors.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: changePercent >= 0
                        ? FintechColors.errorColor
                        : FintechColors.successColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          changePercent >= 0 ? 'Increased by' : 'Decreased by',
                          style: FintechTypography.caption.copyWith(
                            color: FintechColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${changePercent.abs().toStringAsFixed(1)}% ($currencySymbol${change.abs().toStringAsFixed(2)})',
                          style: FintechTypography.bodyMedium.copyWith(
                            color: isDark ? FintechColors.darkText : FintechColors.lightText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String amount,
    String count,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FintechTypography.caption.copyWith(
              color: FintechColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: FintechTypography.h6.copyWith(
              color: isDark ? FintechColors.darkText : FintechColors.lightText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count $label',
            style: FintechTypography.caption.copyWith(
              color: FintechColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider, bool isDark) {
    final categoryTotals = provider.categoryTotals;
    
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(5).toList();
    final totalSpending = categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount);
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? FintechColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  color: FintechColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Top Categories',
                  style: FintechTypography.h6.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...topCategories.map((entry) {
              final percentage = (entry.value / totalSpending) * 100;
              return _buildCategoryItem(
                entry.key,
                entry.value,
                percentage,
                currencySymbol,
                isDark,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String category,
    double amount,
    double percentage,
    String currencySymbol,
    bool isDark,
  ) {
    final color = _getCategoryColor(category);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: FintechTypography.bodyMedium.copyWith(
                      color: isDark ? FintechColors.darkText : FintechColors.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '$currencySymbol${amount.toStringAsFixed(0)}',
                style: FintechTypography.bodyMedium.copyWith(
                  color: isDark ? FintechColors.darkText : FintechColors.lightText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% of total',
            style: FintechTypography.caption.copyWith(
              color: FintechColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ExpenseProvider provider, bool isDark) {
    final recommendations = _generateSmartRecommendations(provider);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? FintechColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: FintechColors.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Recommendations',
                  style: FintechTypography.h6.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => _buildRecommendationCard(rec, isDark)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rec['color'].withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rec['color'].withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rec['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rec['icon'], color: rec['color'], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['title'],
                  style: FintechTypography.bodyMedium.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec['description'],
                  style: FintechTypography.bodySmall.copyWith(
                    color: FintechColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String subtitle, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: FintechColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: FintechTypography.h6.copyWith(
              color: isDark ? FintechColors.darkText : FintechColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: FintechTypography.bodySmall.copyWith(
              color: FintechColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateSmartRecommendations(ExpenseProvider provider) {
    final recommendations = <Map<String, dynamic>>[];
    final categoryTotals = provider.categoryTotals;
    final monthlyTotal = provider.monthlyTotal;

    // High spending alert
    if (monthlyTotal > 3000) {
      recommendations.add({
        'icon': Icons.warning_rounded,
        'title': 'High Monthly Spending',
        'description': 'Your spending is above average. Review your expenses and set category budgets.',
        'color': FintechColors.errorColor,
      });
    }

    // Food spending
    if (categoryTotals['Food'] != null && categoryTotals['Food']! > 500) {
      recommendations.add({
        'icon': Icons.restaurant_rounded,
        'title': 'Reduce Food Costs',
        'description': 'Consider meal planning and cooking at home to save on food expenses.',
        'color': FintechColors.warningColor,
      });
    }

    // Shopping recommendation
    if (categoryTotals['Shopping'] != null && categoryTotals['Shopping']! > 400) {
      recommendations.add({
        'icon': Icons.shopping_bag_rounded,
        'title': 'Control Shopping',
        'description': 'Try the 24-hour rule: wait a day before making non-essential purchases.',
        'color': FintechColors.warningColor,
      });
    }

    // Savings recommendation
    recommendations.add({
      'icon': Icons.savings_rounded,
      'title': 'Build Emergency Fund',
      'description': 'Aim to save 10-15% of your income for unexpected expenses.',
      'color': FintechColors.successColor,
    });

    // Budget tracking
    if (categoryTotals.length >= 3) {
      recommendations.add({
        'icon': Icons.track_changes_rounded,
        'title': 'Set Category Budgets',
        'description': 'Define spending limits for each category to stay on track.',
        'color': FintechColors.infoColor,
      });
    }

    return recommendations;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transport':
        return const Color(0xFF4ECDC4);
      case 'shopping':
        return const Color(0xFFFFE66D);
      case 'entertainment':
        return const Color(0xFFA8E6CF);
      case 'bills':
        return const Color(0xFF95E1D3);
      case 'health':
        return const Color(0xFFFF9AA2);
      default:
        return FintechColors.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}
