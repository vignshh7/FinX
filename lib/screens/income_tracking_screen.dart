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
import '../core/widgets/premium_inputs.dart';
import '../core/widgets/premium_dialogs.dart';
import '../core/widgets/premium_indicators.dart';
import '../core/widgets/loading_skeleton.dart';
import '../providers/income_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/expense_provider.dart';
import '../models/income_model.dart';

class IncomeTrackingScreen extends StatefulWidget {
  const IncomeTrackingScreen({super.key});

  @override
  State<IncomeTrackingScreen> createState() => _IncomeTrackingScreenState();
}

class _IncomeTrackingScreenState extends State<IncomeTrackingScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    await incomeProvider.fetchIncomes();
  }

  void _showAddIncomeDialog() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddIncomeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currency);

    final netSavings = incomeProvider.monthlyTotal - expenseProvider.monthlyTotal;

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
                'Income',
                style: AppTypography.h5.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.successGradient,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),

          incomeProvider.isLoading
              ? _buildLoadingState()
              : _buildContent(incomeProvider, expenseProvider, currencyFormat, netSavings),
        ],
      ),
      floatingActionButton: PremiumFAB(
        icon: Icons.add_rounded,
        label: 'Add Income',
        onPressed: _showAddIncomeDialog,
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
          const ListLoadingSkeleton(itemCount: 5),
        ]),
      ),
    );
  }

  Widget _buildContent(
    IncomeProvider incomeProvider,
    ExpenseProvider expenseProvider,
    NumberFormat format,
    double netSavings,
  ) {
    return SliverPadding(
      padding: EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  label: 'Income',
                  value: format.format(incomeProvider.monthlyTotal),
                  trend: null,
                  color: AppColors.success,
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_down,
                  label: 'Expenses',
                  value: format.format(expenseProvider.monthlyTotal),
                  trend: null,
                  color: AppColors.error,
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          // Net Savings
          GradientCard(
            gradientColors: netSavings >= 0
                ? AppColors.successGradient
                : AppColors.errorGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Savings',
                  style: AppTypography.bodyMd.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  format.format(netSavings),
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  netSavings >= 0
                      ? 'Great! You\'re saving money'
                      : 'Spending more than income',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

          SizedBox(height: AppSpacing.lg),

          // Income List
          Text('Recent Income', style: AppTypography.h6),
          SizedBox(height: AppSpacing.md),

          if (incomeProvider.incomes.isEmpty)
            EmptyState(
              icon: Icons.money_off_rounded,
              title: 'No income yet',
              subtitle: 'Add your first income entry',
              actionText: 'Add Income',
              onAction: _showAddIncomeDialog,
            ).animate().fadeIn()
          else
            ...incomeProvider.incomes.asMap().entries.map((entry) {
              final index = entry.key;
              final income = entry.value;

              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: PremiumCard(
                  onTap: () => _showIncomeDetails(income),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColor(income.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          _getIncomeIcon(income.category),
                          color: AppColors.getCategoryColor(income.category),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              income.source,
                              style: AppTypography.bodyLg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              DateFormat('MMM dd, yyyy').format(income.date),
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AmountDisplay(
                        amount: income.amount,
                        style: AppTypography.h6.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0),
              );
            }),

          SizedBox(height: AppSpacing.xxxl * 2),
        ]),
      ),
    );
  }

  IconData _getIncomeIcon(String category) {
    switch (category) {
      case IncomeCategory.salary:
        return Icons.work_rounded;
      case IncomeCategory.freelance:
        return Icons.computer_rounded;
      case IncomeCategory.investment:
        return Icons.trending_up_rounded;
      case IncomeCategory.business:
        return Icons.business_rounded;
      case IncomeCategory.rental:
        return Icons.home_rounded;
      case IncomeCategory.gift:
        return Icons.card_giftcard_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  void _showIncomeDetails(Income income) {
    // Show details/delete dialog
    PremiumSnackBar.showSuccess(context, 'Income: ${income.source}');
  }
}

class AddIncomeSheet extends StatefulWidget {
  const AddIncomeSheet({super.key});

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = IncomeCategory.salary;
  bool _isRecurring = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      
      await incomeProvider.addIncome(
        Income(
          id: '',
          userId: '',
          source: _sourceController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          date: _selectedDate,
          category: _selectedCategory,
          isRecurring: _isRecurring,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      PremiumSnackBar.showSuccess(context, 'Income added successfully!');
    } catch (e) {
      if (!mounted) return;
      PremiumSnackBar.showError(context, 'Failed to add income');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondaryColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Add Income', style: AppTypography.h5),
              SizedBox(height: AppSpacing.lg),
              
              PremiumTextField(
                controller: _sourceController,
                label: 'Source',
                hint: 'e.g., Monthly Salary',
                prefixIcon: Icons.source_rounded,
              ),
              SizedBox(height: AppSpacing.md),
              
              AmountTextField(
                controller: _amountController,
                label: 'Amount',
              ),
              SizedBox(height: AppSpacing.md),
              
              DatePickerField(
                label: 'Date',
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              SizedBox(height: AppSpacing.md),
              
              DropdownField<String>(
                label: 'Category',
                value: _selectedCategory,
                items: IncomeCategory.allCategories,
                onChanged: (value) => setState(() => _selectedCategory = value!),
                itemLabel: (item) => item,
              ),
              SizedBox(height: AppSpacing.md),
              
              SwitchListTile(
                title: Text('Recurring Income', style: AppTypography.bodyLg),
                value: _isRecurring,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _isRecurring = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: AppSpacing.lg),
              
              PremiumButton(
                text: 'Add Income',
                icon: Icons.check_rounded,
                onPressed: _saveIncome,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
