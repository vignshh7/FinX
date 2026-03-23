import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      await Future.wait([
        budgetProvider.fetchBudgets(),
        expenseProvider.fetchExpenses(),
      ]);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading budget data: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    }
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBudgetDialog(),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => EditBudgetDialog(budget: budget),
    );
  }

  Future<void> _confirmDeleteBudget(Budget budget) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Delete the ${budget.category} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: FintechColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || budget.id == null) return;
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final success = await budgetProvider.deleteBudget(budget.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Budget deleted.' : 'Failed to delete budget.'),
        backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currencySymbol);

    return Scaffold(
      backgroundColor: isDark ? FintechColors.primaryBackground : FintechColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOverviewCard(currencyFormat, isDark),
                  const SizedBox(height: 20),
                  _buildBudgetList(currencyFormat, isDark),
                  const SizedBox(height: 20),
                  _buildBudgetInsights(isDark),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBudgetDialog,
        backgroundColor: FintechColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? FintechColors.primaryBackground : FintechColors.lightBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Budget Management',
          style: FintechTypography.h3.copyWith(
            color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildOverviewCard(NumberFormat currencyFormat, bool isDark) {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, _) {
        final totalBudget = budgetProvider.totalBudget;
        final totalSpent = expenseProvider.monthlyTotal;
        final pastMonthSpent = expenseProvider.pastMonthTotal;
        final remaining = totalBudget - totalSpent;
        final spentPercentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
        final spendingComparison = expenseProvider.getSpendingComparison();

        return Column(
          children: [
            // Main Budget Card
            FintechCard(
              gradient: LinearGradient(
                colors: [
                  FintechColors.primaryColor,
                  FintechColors.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month Budget',
                                style: FintechTypography.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                currencyFormat.format(totalBudget),
                                style: FintechTypography.h2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: LinearProgressIndicator(
                        value: spentPercentage.clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spentPercentage > 1.0 
                              ? FintechColors.errorColor
                              : spentPercentage > 0.8
                                  ? FintechColors.warningColor
                                  : FintechColors.successColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBudgetStat(
                          'Spent', 
                          currencyFormat.format(totalSpent),
                          Colors.white.withOpacity(0.8),
                        ),
                        _buildBudgetStat(
                          remaining >= 0 ? 'Remaining' : 'Over Budget',
                          currencyFormat.format(remaining.abs()),
                          remaining >= 0 ? Colors.white : FintechColors.errorColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Spending Comparison Card
            FintechCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: FintechColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Spending Comparison',
                          style: FintechTypography.h4.copyWith(
                            color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildComparisonStat(
                            'This Month',
                            currencyFormat.format(spendingComparison['currentMonth']),
                            FintechColors.primaryColor,
                            isDark,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark ? FintechColors.borderColor : FintechColors.lightBorderColor,
                        ),
                        Expanded(
                          child: _buildComparisonStat(
                            'Past Month',
                            currencyFormat.format(spendingComparison['pastMonth']),
                            FintechColors.textSecondary,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: spendingComparison['isIncreasing'] 
                            ? FintechColors.errorColor.withOpacity(0.1)
                            : FintechColors.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: spendingComparison['isIncreasing'] 
                              ? FintechColors.errorColor.withOpacity(0.3)
                              : FintechColors.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            spendingComparison['isIncreasing'] 
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: spendingComparison['isIncreasing']
                                ? FintechColors.errorColor
                                : FintechColors.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            spendingComparison['percentageChange'].abs() < 1
                                ? 'Similar spending pattern'
                                : '${spendingComparison['percentageChange'].abs().toStringAsFixed(1)}% ${spendingComparison['isIncreasing'] ? 'increase' : 'decrease'} from last month',
                            style: FintechTypography.bodySmall.copyWith(
                              color: spendingComparison['isIncreasing']
                                  ? FintechColors.errorColor
                                  : FintechColors.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonStat(String label, String amount, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: FintechTypography.h4.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetStat(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          amount,
          style: FintechTypography.h4.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetList(NumberFormat currencyFormat, bool isDark) {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, _) {
        if (budgetProvider.isLoading) {
          return _buildLoadingSkeleton();
        }

        if (budgetProvider.budgets.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Budgets',
              style: FintechTypography.h4.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...budgetProvider.budgets.map((budget) {
              final spent = expenseProvider.getCategoryTotal(budget.category);
              final pastMonthSpent = expenseProvider.getPastMonthCategoryTotal(budget.category);
              final percentage = budget.amount > 0 ? (spent / budget.amount) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBudgetItem(budget, spent, pastMonthSpent, percentage, currencyFormat, isDark),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBudgetItem(
    Budget budget,
    double spent,
    double pastMonthSpent,
    double percentage,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final spendingChange = spent - pastMonthSpent;
    final spendingPercentageChange = pastMonthSpent > 0 ? (spendingChange / pastMonthSpent) * 100 : 0.0;
    
    return FintechCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ExpenseCategory.getColor(budget.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ExpenseCategory.getIcon(budget.category),
                    color: ExpenseCategory.getColor(budget.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: FintechTypography.h5.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(spent)} of ${currencyFormat.format(budget.amount)}',
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: FintechTypography.h5.copyWith(
                    color: percentage > 1.0 
                        ? FintechColors.errorColor
                        : percentage > 0.8
                            ? FintechColors.warningColor
                            : FintechColors.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBudgetDialog(budget);
                    } else if (value == 'delete') {
                      _confirmDeleteBudget(budget);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark
                        ? FintechColors.textSecondary
                        : FintechColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isDark 
                    ? FintechColors.borderColor
                    : FintechColors.borderColor.withOpacity(0.3),
              ),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 1.0 
                      ? FintechColors.errorColor
                      : percentage > 0.8
                          ? FintechColors.warningColor
                          : FintechColors.successColor,
                ),
              ),
            ),
            
            // Past Month Comparison
            if (pastMonthSpent > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: spendingChange > 0 
                      ? FintechColors.errorColor.withOpacity(0.1)
                      : spendingChange < 0 
                          ? FintechColors.successColor.withOpacity(0.1)
                          : FintechColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      spendingChange > 0 
                          ? Icons.trending_up
                          : spendingChange < 0 
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: spendingChange > 0 
                          ? FintechColors.errorColor
                          : spendingChange < 0 
                              ? FintechColors.successColor
                              : FintechColors.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        spendingChange.abs() < 1
                            ? 'Similar to last month (${currencyFormat.format(pastMonthSpent)})'
                            : '${spendingPercentageChange.abs().toStringAsFixed(0)}% ${spendingChange > 0 ? 'more' : 'less'} than last month',
                        style: FintechTypography.caption.copyWith(
                          color: spendingChange > 0 
                              ? FintechColors.errorColor
                              : spendingChange < 0 
                                  ? FintechColors.successColor
                                  : FintechColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInsights(bool isDark) {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, _) {
        final insights = budgetProvider.getBudgetInsights(expenseProvider);
        
        if (insights.isEmpty) return const SizedBox.shrink();

        return FintechCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: FintechColors.accentTeal,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Budget Insights',
                      style: FintechTypography.h5.copyWith(
                        color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FintechColors.accentTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
                          style: FintechTypography.bodyMedium.copyWith(
                            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: FintechColors.borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FintechCard(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: isDark 
                  ? FintechColors.textSecondary
                  : FintechColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Budgets Set',
              style: FintechTypography.h5.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first budget to start tracking your spending goals',
              textAlign: TextAlign.center,
              style: FintechTypography.bodyMedium.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBudgetDialog extends StatefulWidget {
  const AddBudgetDialog({super.key});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = ExpenseCategory.food;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final existingBudget = budgetProvider.getBudgetForCategory(_selectedCategory);
    
    final amount = double.parse(_amountController.text);
    final success = existingBudget != null
        ? await budgetProvider.updateBudget(
            existingBudget.copyWith(
              amount: amount,
              updatedAt: DateTime.now(),
            ),
          )
        : await budgetProvider.addBudget(
            Budget(
              category: _selectedCategory,
              amount: amount,
              period: BudgetPeriod.monthly,
              createdAt: DateTime.now(),
            ),
          );
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? existingBudget != null
                    ? 'Budget updated successfully!'
                    : 'Budget added successfully!'
                : 'Failed to save budget',
          ),
          backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Budget',
                style: FintechTypography.h4.copyWith(
                  color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(ExpenseCategory.getIcon(_selectedCategory)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ExpenseCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          ExpenseCategory.getIcon(category),
                          color: ExpenseCategory.getColor(category),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FintechColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditBudgetDialog extends StatefulWidget {
  final Budget budget;

  const EditBudgetDialog({super.key, required this.budget});

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.budget.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final updated = widget.budget.copyWith(
      amount: double.parse(_amountController.text),
      updatedAt: DateTime.now(),
    );

    final success = await budgetProvider.updateBudget(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Budget updated.' : 'Failed to update budget.'),
        backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Budget',
                style: FintechTypography.h4.copyWith(
                  color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    ExpenseCategory.getIcon(widget.budget.category),
                    color: ExpenseCategory.getColor(widget.budget.category),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.budget.category,
                    style: FintechTypography.bodyMedium.copyWith(
                      color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark
                            ? FintechColors.textSecondary
                            : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FintechColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}