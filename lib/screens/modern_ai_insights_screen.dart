import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/expense_provider.dart';

class ModernAIInsightsScreen extends StatefulWidget {
  const ModernAIInsightsScreen({super.key});

  @override
  State<ModernAIInsightsScreen> createState() => _ModernAIInsightsScreenState();
}

class _ModernAIInsightsScreenState extends State<ModernAIInsightsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  
  Map<String, dynamic>? _insights;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _patterns = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadInsights();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardAnimations = List.generate(
      6, // Number of cards
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.1),
          curve: Curves.easeOutBack,
        ),
      )),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Simulate AI processing
      await Future.delayed(const Duration(seconds: 2));

      _generateInsights(expenseProvider);
      _animationController.forward();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateInsights(ExpenseProvider provider) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Filter expenses by month
    final currentMonthExpenses = provider.expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();
    final lastMonthExpenses = provider.expenses
        .where((e) => e.date.month == lastMonth.month && e.date.year == lastMonth.year)
        .toList();

    // Calculate totals and changes
    final currentTotal = currentMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final lastTotal = lastMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final changePct = lastTotal > 0 ? ((currentTotal - lastTotal) / lastTotal) * 100 : 0.0;

    // Generate insights based on spending analysis

    // Generate natural language insights
    _insights = {
      'spending_summary': _generateSpendingSummary(currentTotal, lastTotal, changePct, currencyFormat),
      'category_insights': _generateCategoryInsights(provider.categoryTotals),
      'frequency_insights': _generateFrequencyInsights(currentMonthExpenses),
    };

    // Generate recommendations
    _recommendations = _generateRecommendations(provider, currentTotal, changePct);
    
    // Generate spending patterns
    _patterns = _generateSpendingPatterns(currentMonthExpenses);
  }

  String _generateSpendingSummary(double current, double last, double changePct, NumberFormat format) {
    if (changePct > 10) {
      return "You've spent ${changePct.abs().toStringAsFixed(1)}% more this month (${format.format(current)}) compared to last month. Consider reviewing your recent purchases.";
    } else if (changePct < -10) {
      return "Great job! You've reduced your spending by ${changePct.abs().toStringAsFixed(1)}% this month. You saved ${format.format(last - current)} compared to last month.";
    } else {
      return "Your spending this month (${format.format(current)}) is consistent with last month. You're maintaining good financial habits.";
    }
  }

  List<String> _generateCategoryInsights(Map<String, double> categoryTotals) {
    final insights = <String>[];
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      final top = sortedCategories.first;
      insights.add("Your highest spending category is ${top.key} at \$${top.value.toStringAsFixed(0)}");
      
      if (sortedCategories.length > 1) {
        final second = sortedCategories[1];
        insights.add("${second.key} is your second highest at \$${second.value.toStringAsFixed(0)}");
      }
    }

    return insights;
  }

  String _generateFrequencyInsights(List expenses) {
    final avgPerDay = expenses.length / DateTime.now().day;
    
    if (avgPerDay > 2) {
      return "You make an average of ${avgPerDay.toStringAsFixed(1)} transactions per day. Consider batching purchases to reduce impulse spending.";
    } else {
      return "You have a controlled spending frequency with ${avgPerDay.toStringAsFixed(1)} transactions per day on average.";
    }
  }

  List<Map<String, dynamic>> _generateRecommendations(provider, double currentTotal, double changePct) {
    final recommendations = <Map<String, dynamic>>[];
    
    if (changePct > 20) {
      recommendations.add({
        'icon': Icons.trending_down,
        'title': 'Reduce Spending',
        'description': 'Your spending increased significantly. Try the 24-hour rule before making non-essential purchases.',
        'color': FintechColors.errorColor,
        'priority': 'high',
      });
    }

    if (provider.categoryTotals['Food'] != null && provider.categoryTotals['Food']! > 800) {
      recommendations.add({
        'icon': Icons.restaurant,
        'title': 'Food Budget Alert',
        'description': 'Food spending is above average. Consider meal planning and cooking at home more often.',
        'color': FintechColors.warningColor,
        'priority': 'medium',
      });
    }

    recommendations.add({
      'icon': Icons.savings,
      'title': 'Build Emergency Fund',
      'description': 'Aim to save 10-15% of your income for unexpected expenses. Start with small amounts.',
      'color': FintechColors.successColor,
      'priority': 'medium',
    });

    recommendations.add({
      'icon': Icons.analytics,
      'title': 'Track Categories',
      'description': 'Set spending limits for each category to better control your budget.',
      'color': FintechColors.infoColor,
      'priority': 'low',
    });

    return recommendations;
  }

  List<Map<String, dynamic>> _generateSpendingPatterns(List expenses) {
    final patterns = <Map<String, dynamic>>[];
    
    // Weekend vs Weekday spending
    final weekendSpending = expenses.where((e) => 
      e.date.weekday == DateTime.saturday || e.date.weekday == DateTime.sunday
    ).fold(0.0, (sum, e) => sum + e.amount);
    
    final weekdaySpending = expenses.where((e) => 
      e.date.weekday != DateTime.saturday && e.date.weekday != DateTime.sunday
    ).fold(0.0, (sum, e) => sum + e.amount);

    if (weekendSpending > weekdaySpending * 0.4) {
      patterns.add({
        'title': 'Weekend Spender',
        'description': 'You tend to spend more on weekends. Plan weekend activities with set budgets.',
        'value': weekendSpending,
        'icon': Icons.weekend,
      });
    }

    // Time-based patterns
    final morningExpenses = expenses.where((e) => e.date.hour < 12).length;
    final eveningExpenses = expenses.where((e) => e.date.hour >= 18).length;
    
    if (eveningExpenses > morningExpenses * 1.5) {
      patterns.add({
        'title': 'Evening Shopper',
        'description': 'Most of your purchases happen in the evening. Late shopping can lead to impulse buys.',
        'value': eveningExpenses.toDouble(),
        'icon': Icons.nights_stay,
      });
    }

    return patterns;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _isLoading
                          ? Center(child: CircularProgressIndicator(color: cs.primary))
                          : _buildInsightsContent(),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildInsightsContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 100,
          floating: true,
          pinned: true,
          backgroundColor: FintechColors.primaryBackground,
          title: Text(
            'AI Insights',
            style: FintechTypography.h4.copyWith(
              color: FintechColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadInsights,
            ),
          ],
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Insight Card
                _buildAnimatedCard(0, _buildMainInsightCard()),
                const SizedBox(height: 24),
                
                // Recommendations Section
                _buildSectionTitle('Recommendations for You'),
                const SizedBox(height: 16),
                ..._recommendations.asMap().entries.map((entry) =>
                  _buildAnimatedCard(entry.key + 1, _buildRecommendationCard(entry.value)),
                ),
                
                const SizedBox(height: 24),
                
                // Spending Patterns
                if (_patterns.isNotEmpty) ...[
                  _buildSectionTitle('Your Spending Patterns'),
                  const SizedBox(height: 16),
                  ..._patterns.asMap().entries.map((entry) =>
                    _buildAnimatedCard(entry.key + 4, _buildPatternCard(entry.value)),
                  ),
                ],
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    if (index >= _cardAnimations.length) return child;
    
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimations[index].value)),
          child: Opacity(
            opacity: _cardAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMainInsightCard() {
    if (_insights == null) return const SizedBox();
    
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FintechCard(
      gradient: LinearGradient(
        colors: [cs.primary, cs.primaryContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: cs.onPrimary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Spending Analysis',
                  style: FintechTypography.h5.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _insights!['spending_summary'],
            style: FintechTypography.bodyLarge.copyWith(
              color: cs.onPrimary.withOpacity(0.9),
              height: 1.6,
            ),
          ),
          if (_insights!['category_insights'].isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._insights!['category_insights'].map<Widget>((insight) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: cs.onPrimary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: FintechTypography.bodyMedium.copyWith(
                          color: cs.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FintechCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (recommendation['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                recommendation['icon'],
                color: recommendation['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        recommendation['title'],
                        style: FintechTypography.h6.copyWith(
                          color: FintechColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (recommendation['priority'] == 'high')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FintechColors.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'High Priority',
                            style: FintechTypography.labelSmall.copyWith(
                              color: FintechColors.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation['description'],
                    style: FintechTypography.bodySmall.copyWith(
                      color: FintechColors.textSecondary,
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

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FintechCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FintechColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                pattern['icon'],
                color: FintechColors.infoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern['title'],
                    style: FintechTypography.h6.copyWith(
                      color: FintechColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pattern['description'],
                    style: FintechTypography.bodySmall.copyWith(
                      color: FintechColors.textSecondary,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: FintechTypography.h5.copyWith(
        color: FintechColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}