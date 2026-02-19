import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
      
      // Fetch all comprehensive AI data
      await expenseProvider.loadAllAIData(forceRefresh: true);
      
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading AI insights: ${e.toString()}'),
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
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          _buildAppBar(isDark),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _buildPredictionCard(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildMonthlyComparisonCard(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildCompleteAIAnalysisSection(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildFinancialAdviceSection(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildAlertsSection(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildSpendingAggregationSection(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildSpendingAnalysis(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildCategoryBreakdown(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildEnhancedAIInsightsSection(expenseProvider, isDark),
                                const SizedBox(height: 20),
                                _buildRecommendations(expenseProvider, isDark),
                                SizedBox(height: bottomPadding + 100),
                              ]),
                            ),
                          ),
                        ],
                      ),
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
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
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

    final _rawPrediction = prediction['next_month_prediction'] ?? prediction['predicted_amount'] ?? 0.0;
    final nextMonthPrediction = (_rawPrediction is num) ? _rawPrediction.toDouble() : 0.0;
    final _rawConfidence = prediction['confidence'] ?? 0.0;
    final confidence = (_rawConfidence is num) ? _rawConfidence.toDouble() : 0.0;
    final trend = prediction['trend'] ?? 'stable';
    
    final llmSections = provider.aiInsights is Map
        ? (provider.aiInsights?['llm']?['sections'] as Map?)
        : null;

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
                      if (llmSections != null) ...[
                        const SizedBox(height: 16),
                        _buildSectionLlmInsight(llmSections, 'prediction', isDark),
                      ],
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

  Widget _buildMonthlyComparisonCard(ExpenseProvider provider, bool isDark) {
    final comparison = provider.getSpendingComparison();
    final current = (comparison['currentMonth'] as num?)?.toDouble() ?? 0.0;
    final past = (comparison['pastMonth'] as num?)?.toDouble() ?? 0.0;
    final difference = (comparison['difference'] as num?)?.toDouble() ?? 0.0;
    final percentage = (comparison['percentageChange'] as num?)?.toDouble() ?? 0.0;
    final isIncreasing = comparison['isIncreasing'] == true;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;
    final total = current + past;
    final currentRatio = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? FintechColors.borderColor : FintechColors.lightBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: FintechColors.accentTeal,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Monthly Comparison',
                style: FintechTypography.h5.copyWith(
                  color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildComparisonStat(
                  'This Month',
                  '$currencySymbol${current.toStringAsFixed(2)}',
                  FintechColors.accentTeal,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildComparisonStat(
                  'Past Month',
                  '$currencySymbol${past.toStringAsFixed(2)}',
                  FintechColors.textSecondary,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: currentRatio,
              minHeight: 8,
              backgroundColor: isDark
                  ? FintechColors.borderColor
                  : FintechColors.lightBorderColor,
              valueColor: AlwaysStoppedAnimation<Color>(FintechColors.accentTeal),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isIncreasing ? Icons.trending_up : Icons.trending_down,
                color: isIncreasing ? FintechColors.errorColor : FintechColors.successColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  percentage.abs() < 1
                      ? 'Similar to last month'
                      : '${percentage.abs().toStringAsFixed(1)}% ${isIncreasing ? 'increase' : 'decrease'}',
                  style: FintechTypography.bodySmall.copyWith(
                    color: isIncreasing ? FintechColors.errorColor : FintechColors.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${difference >= 0 ? '+' : '-'}$currencySymbol${difference.abs().toStringAsFixed(2)}',
                style: FintechTypography.bodySmall.copyWith(
                  color: isIncreasing ? FintechColors.errorColor : FintechColors.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStat(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: FintechTypography.h5.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(ExpenseProvider provider, bool isDark) {
    final alerts = provider.alerts;
    final llmSections = provider.aiInsights is Map
        ? (provider.aiInsights?['llm']?['sections'] as Map?)
        : null;
    
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
            if (llmSections != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildSectionLlmInsight(llmSections, 'anomalies', isDark),
              ),
            ],
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
    final title = alert['title']?.toString();
    final message = alert['message']?.toString() ?? 'No message';
    final recommendation = alert['recommendation']?.toString();
    final category = alert['category']?.toString();
    final priority = alert['priority']?.toString();

    IconData icon;
    Color color;

    switch (type) {
      case 'warning':
        icon = Icons.warning_rounded;
        color = FintechColors.warningColor;
        break;
      case 'critical':
      case 'alert':
        icon = Icons.error_rounded;
        color = FintechColors.errorColor;
        break;
      case 'positive':
        icon = Icons.check_circle_rounded;
        color = FintechColors.successColor;
        break;
      case 'suggestion':
        icon = Icons.tips_and_updates;
        color = FintechColors.infoColor;
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
                Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title,
                          style: FintechTypography.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (priority != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: FintechTypography.caption.copyWith(
                            color: color, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (title != null) const SizedBox(height: 4),
                Text(
                  message,
                  style: FintechTypography.bodySmall.copyWith(
                    color: isDark ? FintechColors.darkText : FintechColors.lightText,
                    height: 1.4,
                  ),
                ),
                if (recommendation != null) ...
                  [
                    const SizedBox(height: 6),
                    Text(
                      '→ $recommendation',
                      style: FintechTypography.caption.copyWith(
                        color: color,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
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

    final currentTotal = currentMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final lastTotal = lastMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    
    final change = currentTotal - lastTotal;
    final changePercent = lastTotal > 0 ? (change / lastTotal) * 100 : 0.0;
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;

    final llmSections = provider.aiInsights is Map
        ? (provider.aiInsights?['llm']?['sections'] as Map?)
        : null;

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
                        if (llmSections != null) ...[
                          const SizedBox(height: 12),
                          _buildSectionLlmInsight(llmSections, 'patterns', isDark),
                        ],
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
    final totalSpending = categoryTotals.values.fold<double>(0.0, (sum, amount) => sum + amount);
    
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
              final percentage = (entry.value / (totalSpending > 0 ? totalSpending : 1.0)) * 100;
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

    if (monthlyTotal <= 0) return recommendations;

    // Find top spending category
    MapEntry<String, double>? topCat;
    if (categoryTotals.isNotEmpty) {
      topCat = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    }

    // High spending: top category > 40% of total
    if (topCat != null && topCat.value / monthlyTotal > 0.40) {
      recommendations.add({
        'icon': Icons.warning_rounded,
        'title': '${topCat.key} is Your Biggest Expense',
        'description': '${topCat.key} takes ${(topCat.value / monthlyTotal * 100).toStringAsFixed(1)}% of your monthly spend (${topCat.value.toStringAsFixed(0)}). Consider ways to reduce it.',
        'color': FintechColors.errorColor,
      });
    }

    // Food-specific tip
    final foodKey = categoryTotals.keys.firstWhere(
        (k) => k.toLowerCase().contains('food') || k.toLowerCase().contains('dining'),
        orElse: () => '');
    if (foodKey.isNotEmpty && categoryTotals[foodKey]! / monthlyTotal > 0.25) {
      recommendations.add({
        'icon': Icons.restaurant_rounded,
        'title': 'Reduce Food Costs',
        'description': 'Food & dining is ${(categoryTotals[foodKey]! / monthlyTotal * 100).toStringAsFixed(0)}% of spending. Meal planning and home cooking can cut this significantly.',
        'color': FintechColors.warningColor,
      });
    }

    // Shopping-specific tip
    final shopKey = categoryTotals.keys.firstWhere(
        (k) => k.toLowerCase().contains('shop') || k.toLowerCase().contains('retail'),
        orElse: () => '');
    if (shopKey.isNotEmpty && categoryTotals[shopKey]! / monthlyTotal > 0.20) {
      recommendations.add({
        'icon': Icons.shopping_bag_rounded,
        'title': 'Review Shopping Habits',
        'description': 'Shopping is ${(categoryTotals[shopKey]! / monthlyTotal * 100).toStringAsFixed(0)}% of spending. Try the 24-hour rule before non-essential purchases.',
        'color': FintechColors.warningColor,
      });
    }

    // Many small categories — suggest consolidation
    if (categoryTotals.length >= 5) {
      recommendations.add({
        'icon': Icons.track_changes_rounded,
        'title': 'Set Category Budgets',
        'description': 'You spend across ${categoryTotals.length} categories. Setting per-category limits in Budget Management will help you stay on track.',
        'color': FintechColors.infoColor,
      });
    }

    // Savings suggestion: use actual backend advice or generic
    final adviceData = provider.financialAdvice;
    final backendAdvice = adviceData != null ? (adviceData['advice'] as List? ?? []) : [];
    final hasSavingsTip = backendAdvice.any((a) =>
        (a['category'] ?? '').toString().contains('savings'));
    if (!hasSavingsTip) {
      final comparison = provider.getSpendingComparison();
      final isDecreasing = comparison['isIncreasing'] != true;
      recommendations.add({
        'icon': Icons.savings_rounded,
        'title': isDecreasing ? 'Great — Spending is Down!' : 'Build an Emergency Fund',
        'description': isDecreasing
            ? 'Your spending dropped vs last month. Channel those savings into an emergency fund or investments.'
            : 'Aim to save 10–15% of your monthly income for unexpected expenses.',
        'color': FintechColors.successColor,
      });
    }

    // Add high-priority backend advice items as recommendations
    for (final a in backendAdvice.take(2)) {
      if (a is Map) {
        recommendations.add({
          'icon': _adviceTypeIcon(a['type']?.toString() ?? 'suggestion'),
          'title': a['title']?.toString() ?? 'Tip',
          'description': '${a['message'] ?? ''} ${a['recommendation'] ?? ''}'.trim(),
          'color': _adviceTypeColor(a['type']?.toString() ?? 'suggestion'),
        });
      }
    }

    return recommendations;
  }

  IconData _adviceTypeIcon(String type) {
    switch (type) {
      case 'warning': return Icons.warning_rounded;
      case 'alert': return Icons.error_rounded;
      case 'positive': return Icons.thumb_up_rounded;
      default: return Icons.tips_and_updates;
    }
  }

  Color _adviceTypeColor(String type) {
    switch (type) {
      case 'warning': return FintechColors.warningColor;
      case 'alert': return FintechColors.errorColor;
      case 'positive': return FintechColors.successColor;
      default: return FintechColors.infoColor;
    }
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

  // =================================
  // NEW COMPREHENSIVE AI SECTIONS
  // =================================

  Widget _buildCompleteAIAnalysisSection(ExpenseProvider provider, bool isDark) {
    final analysis = provider.completeAIAnalysis;

    if (analysis == null) {
      return _buildEmptyCard(
        'Complete AI Analysis',
        'Loading comprehensive financial analysis...',
        Icons.psychology,
        isDark,
      );
    }

    // Extract fields from the backend response
    final prediction = analysis['prediction'] is Map ? analysis['prediction'] as Map : null;
    final aggregation = analysis['aggregation'] is Map ? analysis['aggregation'] as Map : null;
    // anomalies key is a Map with an inner 'anomalies' list
    final anomaliesMap = analysis['anomalies'] is Map ? analysis['anomalies'] as Map : null;
    final anomalyList = anomaliesMap?['anomalies'] is List ? anomaliesMap!['anomalies'] as List : <dynamic>[];
    final advice = analysis['advice'] is Map ? analysis['advice'] as Map : null;
    final insightsMap = analysis['insights'] is Map ? analysis['insights'] as Map : null;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final cur = themeProvider.currencySymbol;

    // Build summary stats
    final predAmt = prediction != null
        ? ((prediction['next_month_prediction'] ?? prediction['predicted_amount'] ?? 0.0) as num).toDouble()
        : null;
    final confidence = prediction != null
        ? ((prediction['confidence'] ?? 0.0) as num).toDouble()
        : null;
    final totalCategories = aggregation?['total_categories'] as int? ??
        (aggregation?['category_totals'] is Map ? (aggregation!['category_totals'] as Map).length : null);
    final avgMonthly = aggregation != null
        ? ((aggregation['average_monthly'] ?? aggregation['avg_monthly_spend'] ?? 0.0) as num).toDouble()
        : null;
    final anomalyCount = anomalyList.length;
    final adviceList = advice != null
        ? ((advice['advice'] ?? advice['recommendations'] ?? []) as List)
        : <dynamic>[];
    final insightTexts = insightsMap != null
        ? ((insightsMap['insights'] ?? []) as List)
        : <dynamic>[];

    final statColor = isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary;
    final subColor = isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FintechColors.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FintechColors.primaryColor, FintechColors.primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete AI Analysis',
                        style: FintechTypography.h4.copyWith(color: statColor, fontWeight: FontWeight.bold)),
                    Text('Full pipeline summary', style: FintechTypography.bodyMedium.copyWith(color: subColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick stat chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (predAmt != null)
                _buildStatChip(Icons.trending_up, 'Next Month', '$cur${predAmt.toStringAsFixed(0)}',
                    FintechColors.primaryColor, isDark),
              if (confidence != null)
                _buildStatChip(Icons.verified, 'Confidence', '${(confidence * 100).toStringAsFixed(0)}%',
                    FintechColors.successColor, isDark),
              if (avgMonthly != null)
                _buildStatChip(Icons.calculate, 'Avg Monthly', '$cur${avgMonthly.toStringAsFixed(0)}',
                    FintechColors.accentTeal, isDark),
              if (totalCategories != null)
                _buildStatChip(Icons.category, 'Categories', '$totalCategories',
                    FintechColors.warningColor, isDark),
              _buildStatChip(Icons.warning_rounded, 'Anomalies', '$anomalyCount',
                  anomalyCount > 0 ? FintechColors.errorColor : FintechColors.successColor, isDark),
            ],
          ),

          // Insights from AI
          if (insightTexts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('AI Observations',
                style: FintechTypography.caption.copyWith(color: subColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...insightTexts.take(4).map((item) {
              final text = item is Map ? (item['text'] ?? item.toString()) : item.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: FintechColors.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text.toString(),
                          style: FintechTypography.bodySmall.copyWith(color: statColor, height: 1.4)),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Top advice
          if (adviceList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Top Recommendations',
                style: FintechTypography.caption.copyWith(color: subColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...adviceList.take(3).map((item) {
              final text = item is Map ? (item['message'] ?? item['advice'] ?? item.toString()) : item.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates, size: 16, color: FintechColors.accentTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text.toString(),
                          style: FintechTypography.bodySmall.copyWith(color: statColor, height: 1.4)),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (insightTexts.isEmpty && adviceList.isEmpty) ...[
            const SizedBox(height: 12),
            Text('No detailed insights available yet. Add more expenses to unlock AI analysis.',
                style: FintechTypography.bodyMedium.copyWith(color: subColor, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: FintechTypography.caption.copyWith(
                      color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      fontSize: 9)),
              Text(value,
                  style: FintechTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAdviceSection(ExpenseProvider provider, bool isDark) {
    final advice = provider.financialAdvice;
    
    if (advice == null) {
      return _buildEmptyCard(
        'Financial Advisor',
        'Getting personalized financial advice...',
        Icons.lightbulb_outline,
        isDark,
      );
    }

    final recommendations = (advice['advice'] ?? advice['recommendations'] ?? []) as List;
    final llmSections = provider.aiInsights is Map
      ? (provider.aiInsights?['llm']?['sections'] as Map?)
      : null;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FintechColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FintechColors.accentGreen, FintechColors.accentGreen.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Advisor',
                      style: FintechTypography.h4.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI-powered recommendations',
                      style: FintechTypography.bodyMedium.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...recommendations.map<Widget>((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAdviceItem(rec, isDark),
          )),
          if (recommendations.isEmpty) 
            Text(
              'No specific recommendations at this time. Keep tracking your expenses!',
              style: FintechTypography.bodyMedium.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (llmSections != null) ...[
            const SizedBox(height: 16),
            _buildSectionLlmInsight(llmSections, 'advice', isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSpendingAggregationSection(ExpenseProvider provider, bool isDark) {
    final aggregation = provider.spendingAggregation ?? _buildLocalAggregation(provider);
    
    if (aggregation == null) {
      return _buildEmptyCard(
        'Spending Patterns',
        'Analyzing your spending patterns...',
        Icons.analytics_outlined,
        isDark,
      );
    }

    final llmSections = provider.aiInsights is Map
      ? (provider.aiInsights?['llm']?['sections'] as Map?)
      : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FintechColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FintechColors.successColor, FintechColors.successColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Patterns',
                      style: FintechTypography.h4.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monthly spending trends',
                      style: FintechTypography.bodyMedium.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (aggregation['monthly_totals'] != null) 
            _buildMonthlyTotalsChart(aggregation['monthly_totals'], isDark),
          if (aggregation['category_totals'] != null) ...[
            const SizedBox(height: 20),
            _buildCategoryTotalsChart(aggregation['category_totals'], isDark),
          ],
          const SizedBox(height: 16),
          _buildPatternInsightsFallback(aggregation, isDark),
          if (llmSections != null) ...[
            const SizedBox(height: 12),
            _buildSectionLlmInsight(llmSections, 'patterns', isDark),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _buildLocalAggregation(ExpenseProvider provider) {
    if (provider.expenses.isEmpty) return null;

    final monthlyTotals = <String, double>{};
    final categoryTotals = <String, double>{};
    double overall = 0.0;

    for (final expense in provider.expenses) {
      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + expense.amount;
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
      overall += expense.amount;
    }

    return {
      'monthly_totals': monthlyTotals,
      'category_totals': categoryTotals,
      'overall_total': overall,
      'months_analyzed': monthlyTotals.length,
      'average_monthly': monthlyTotals.isNotEmpty ? overall / monthlyTotals.length : 0.0,
    };
  }

  Widget _buildEnhancedAIInsightsSection(ExpenseProvider provider, bool isDark) {
    final insights = provider.aiInsights;
    
    if (insights == null) {
      return _buildEmptyCard(
        'AI Insights',
        'Generating intelligent insights...',
        Icons.auto_awesome,
        isDark,
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FintechColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FintechColors.warningColor, FintechColors.warningColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: FintechTypography.h4.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Smart analysis of your finances',
                      style: FintechTypography.bodyMedium.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (insights['insights'] != null) ...[
            for (final insight in insights['insights'] as List<dynamic>)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInsightItem(insight, isDark),
              ),
          ],
          if (insights['llm'] != null) ...[
            const SizedBox(height: 16),
            _buildLlmInsights(insights['llm'], isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLlmInsight(Map? sections, String key, bool isDark) {
    if (sections == null || sections[key] == null) {
      return const SizedBox.shrink();
    }

    final data = sections[key] as Map;
    final summary = data['summary']?.toString() ?? '';
    final bullets = data['bullets'] is List ? data['bullets'] as List : const [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? FintechColors.darkSurface
            : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FintechColors.accentTeal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.isNotEmpty) ...[
            Text(
              summary,
              style: FintechTypography.bodySmall.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...bullets.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: FintechColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPatternInsightsFallback(Map aggregation, bool isDark) {
    final monthlyTotals = aggregation['monthly_totals'] is Map
        ? Map<String, dynamic>.from(aggregation['monthly_totals'])
        : <String, dynamic>{};
    final categoryTotals = aggregation['category_totals'] is Map
        ? Map<String, dynamic>.from(aggregation['category_totals'])
        : <String, dynamic>{};

    if (monthlyTotals.isEmpty && categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    String? topCategory;
    double topAmount = 0.0;
    categoryTotals.forEach((key, value) {
      final amount = (value is num) ? value.toDouble() : 0.0;
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = key;
      }
    });

    final months = monthlyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final trend = months.length >= 2
        ? ((months.last.value as num).toDouble() - (months.first.value as num).toDouble())
        : 0.0;

    final insights = <String>[];
    if (topCategory != null) {
      insights.add('Top category: $topCategory');
    }
    if (months.length >= 2) {
      insights.add(trend >= 0 ? 'Spending trend is rising' : 'Spending trend is easing');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? FintechColors.primaryColor.withOpacity(0.08)
            : FintechColors.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FintechColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Highlights',
            style: FintechTypography.caption.copyWith(
              color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...insights.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: FintechTypography.bodySmall.copyWith(
                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLlmInsights(dynamic llm, bool isDark) {
    final summary = llm is Map ? (llm['summary']?.toString() ?? '') : llm.toString();
    final highlights = llm is Map && llm['highlights'] is List ? llm['highlights'] as List : const [];
    final risks = llm is Map && llm['risks'] is List ? llm['risks'] as List : const [];
    final actions = llm is Map && llm['actions'] is List ? llm['actions'] as List : const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? FintechColors.darkSurface
            : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FintechColors.accentTeal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_alt,
                color: FintechColors.accentTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'LLM Summary',
                style: FintechTypography.h6.copyWith(
                  color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              style: FintechTypography.bodySmall.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ],
          _buildLlmList('Highlights', highlights, isDark),
          _buildLlmList('Risks', risks, isDark),
          _buildLlmList('Actions', actions, isDark),
        ],
      ),
    );
  }

  Widget _buildLlmList(String title, List items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FintechTypography.caption.copyWith(
              color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: FintechColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Helper methods for new sections
  Widget _buildAdviceItem(dynamic advice, bool isDark) {
    final isMap = advice is Map;
    final type = isMap ? (advice['type']?.toString() ?? 'suggestion') : 'suggestion';
    final title = isMap ? advice['title']?.toString() : null;
    final message = isMap ? (advice['message']?.toString() ?? advice.toString()) : advice.toString();
    final recommendation = isMap ? advice['recommendation']?.toString() : null;
    final priority = isMap ? advice['priority']?.toString() : null;

    final color = _adviceTypeColor(type);
    final icon = _adviceTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title,
                          style: FintechTypography.bodySmall.copyWith(
                            color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (priority != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: FintechTypography.caption.copyWith(
                            color: color, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (title != null) const SizedBox(height: 4),
                Text(
                  message,
                  style: FintechTypography.bodySmall.copyWith(
                    color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                if (recommendation != null) ...
                  [
                    const SizedBox(height: 5),
                    Text(
                      '→ $recommendation',
                      style: FintechTypography.caption.copyWith(
                        color: color,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(dynamic insight, bool isDark) {
    // insight can be a String or a Map with 'title' and 'text' keys
    String? title;
    String text;
    if (insight is Map) {
      title = insight['title']?.toString();
      text = insight['text']?.toString() ?? insight.toString();
    } else {
      text = insight.toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? FintechColors.primaryBlue.withOpacity(0.1)
            : FintechColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FintechColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: FintechColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...
                  [
                    Text(
                      title,
                      style: FintechTypography.bodyMedium.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                Text(
                  text,
                  style: FintechTypography.bodyMedium.copyWith(
                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> metrics, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.keys.length > 4 ? 4 : metrics.keys.length,
      itemBuilder: (context, index) {
        final key = metrics.keys.elementAt(index);
        final value = metrics[key];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? FintechColors.primaryColor.withOpacity(0.1)
                : FintechColors.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: FintechTypography.h5.copyWith(
                  color: FintechColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                key.replaceAll('_', ' ').toUpperCase(),
                style: FintechTypography.caption.copyWith(
                  color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTotalsChart(dynamic monthlyData, bool isDark) {
    if (monthlyData is! Map || monthlyData.isEmpty) return const SizedBox.shrink();

    final entries = monthlyData.entries
        .map((e) => MapEntry(e.key.toString(), (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final recentEntries = entries.length > 6 ? entries.sublist(entries.length - 6) : entries;
    if (recentEntries.isEmpty) return const SizedBox.shrink();

    final maxVal = recentEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final barGroups = recentEntries.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.value,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                FintechColors.primaryColor,
                FintechColors.primaryColor.withOpacity(0.6),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Spending Trend',
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              minY: 0,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: FintechColors.borderColor.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxVal > 0 ? maxVal / 4 : 1,
                    getTitlesWidget: (value, _) => Text(
                      value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                      style: FintechTypography.caption.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= recentEntries.length) return const SizedBox.shrink();
                      final label = recentEntries[idx].key;
                      final parts = label.split('-');
                      final short = parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : label;
                      return Text(
                        short,
                        style: FintechTypography.caption.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '₹${rod.toY.toStringAsFixed(0)}',
                    FintechTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTotalsChart(dynamic categoryData, bool isDark) {
    if (categoryData is! Map || categoryData.isEmpty) return const SizedBox.shrink();

    final entries = categoryData.entries
        .map((e) => MapEntry(e.key.toString(), (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxVal = top.first.value;
    final total = top.fold<double>(0, (sum, e) => sum + e.value);

    final categoryColors = [
      FintechColors.primaryColor,
      FintechColors.accentTeal,
      FintechColors.successColor,
      FintechColors.warningColor,
      FintechColors.errorColor,
      Colors.purple,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Spending Categories',
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...top.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final pct = maxVal > 0 ? cat.value / maxVal : 0.0;
          final share = total > 0 ? (cat.value / total * 100) : 0.0;
          final color = categoryColors[idx % categoryColors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat.key,
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${cat.value >= 1000 ? "${(cat.value / 1000).toStringAsFixed(1)}k" : cat.value.toStringAsFixed(0)}',
                      style: FintechTypography.bodySmall.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${share.toStringAsFixed(1)}%)',
                      style: FintechTypography.caption.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
