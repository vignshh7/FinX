import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Optimized parallel data loading
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all data in parallel for faster performance
      await Future.wait([
        context.read<ExpenseProvider>().fetchExpenses(),
        context.read<IncomeProvider>().fetchIncomes(),
        context.read<SubscriptionProvider>().fetchSubscriptions(),
      ]);

      // Add small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading ? _buildLoadingSkeleton(isDark) : _buildContent(isDark),
    );
  }

  // Skeleton loading for smooth UX
  Widget _buildLoadingSkeleton(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF1A1D23) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF2A2D33) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: backgroundColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Header skeleton
            Row(
              children: [
                Container(width: 100, height: 20, decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(4))),
                const Spacer(),
                Container(width: 60, height: 20, decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(4))),
              ],
            ),
            const SizedBox(height: 24),
            // Balance card skeleton
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Quick actions skeleton
            Row(
              children: [
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)))),
              ],
            ),
            const SizedBox(height: 20),
            // Recent transactions skeleton
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(isDark),
              const SizedBox(height: 20),
              _buildQuickActions(isDark),
              const SizedBox(height: 20),
              _buildRecentTransactions(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = Theme.of(context);
        
        return Row(
          children: [
            Text(
              'Welcome back!',
              style: FintechTypography.h2.copyWith(
                color: theme.colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            // Theme toggle button
            IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              tooltip: 'Toggle theme',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return Consumer3<ExpenseProvider, IncomeProvider, ThemeProvider>(
      builder: (context, expenseProvider, incomeProvider, themeProvider, _) {
        final totalIncome = incomeProvider.total;
        final totalExpenses = expenseProvider.total;
        final balance = totalIncome - totalExpenses;
        final budget = themeProvider.monthlyBudget;
        final budgetUsed = totalExpenses / budget;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FintechColors.primaryBlue,
                FintechColors.primaryBlue.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: FintechColors.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance',
                style: FintechTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: FintechTypography.h1.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Budget progress
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Used',
                          style: FintechTypography.caption.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: budgetUsed.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(
                            budgetUsed > 1.0 ? Colors.red : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(budgetUsed * 100).toInt()}%',
                    style: FintechTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        _buildActionCard(
          icon: Icons.add_circle,
          title: 'Add Expense',
          color: cs.error,
          onTap: () => Navigator.pushNamed(context, '/add_expense'),
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.trending_up,
          title: 'Add Income',
          color: cs.secondary,
          onTap: () => Navigator.pushNamed(context, '/income_tracking'),
        ),
        const SizedBox(width: 12),
        _buildActionCard(
          icon: Icons.camera_alt,
          title: 'Scan Receipt',
          color: cs.primary,
          onTap: () => Navigator.pushNamed(context, '/ocr_screen'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: FintechTypography.caption.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        final recentExpenses = expenseProvider.expenses.take(5).toList();
        final theme = Theme.of(context);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Transactions',
                  style: FintechTypography.h3.copyWith(
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/expense_history'),
                  child: Text(
                    'See All',
                    style: FintechTypography.bodyMedium.copyWith(
                      color: FintechColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: FintechTypography.bodyLarge.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your first expense to get started',
                        style: FintechTypography.caption.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentExpenses.map((expense) => _buildTransactionItem(expense, theme)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(dynamic expense, ThemeData theme) {
    final cs = theme.colorScheme;
    final categoryColors = {
      'Food': cs.secondary,
      'Transport': cs.primary,
      'Shopping': cs.tertiary ?? cs.primary,
      'Entertainment': cs.secondaryContainer,
      'Bills': cs.error,
      'Healthcare': cs.primaryContainer,
      'Other': cs.outline,
    };
    final categoryColor = categoryColors[expense.category] ?? cs.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ?? expense.category,
                  style: FintechTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  expense.category,
                  style: FintechTypography.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-\${expense.amount.toStringAsFixed(2)}',
            style: FintechTypography.bodyMedium.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
        return Icons.receipt;
      case 'healthcare':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }
}