import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/income_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/income_model.dart';

class IncomeTrackingScreenNew extends StatefulWidget {
  const IncomeTrackingScreenNew({super.key});

  @override
  State<IncomeTrackingScreenNew> createState() => _IncomeTrackingScreenNewState();
}

class _IncomeTrackingScreenNewState extends State<IncomeTrackingScreenNew> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        Provider.of<IncomeProvider>(context, listen: false).fetchIncomes(),
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: FintechColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddIncomeDialog() {
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
    final currencySymbol = themeProvider.currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    final netSavings = incomeProvider.monthlyTotal - expenseProvider.monthlyTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Tracking'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Monthly Income',
                            value: currencyFormat.format(incomeProvider.monthlyTotal),
                            icon: Icons.trending_up,
                            iconColor: FintechColors.successColor,
                            valueColor: FintechColors.successColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            title: 'Expenses',
                            value: currencyFormat.format(expenseProvider.monthlyTotal),
                            icon: Icons.trending_down,
                            iconColor: FintechColors.errorColor,
                            valueColor: FintechColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Net Savings Card
                    FintechCard(
                      gradient: netSavings >= 0
                          ? FintechColors.primaryGradient
                          : LinearGradient(
                              colors: [FintechColors.errorColor, FintechColors.warningColor],
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Savings',
                                style: FintechTypography.labelLarge.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Icon(
                                netSavings >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(netSavings.abs()),
                            style: FintechTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            netSavings >= 0
                                ? '${((netSavings / incomeProvider.monthlyTotal) * 100).toStringAsFixed(1)}% of income saved'
                                : 'Spending exceeds income',
                            style: FintechTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Income List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Income History', style: FintechTypography.h5),
                        Text(
                          '${incomeProvider.incomes.length} entries',
                          style: FintechTypography.bodyMedium.copyWith(
                            color: FintechColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Income List
                    if (incomeProvider.incomes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: FintechColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No income recorded yet',
                                style: FintechTypography.bodyLarge.copyWith(
                                  color: FintechColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first income entry',
                                style: FintechTypography.bodySmall.copyWith(
                                  color: FintechColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...incomeProvider.incomes.map((income) => _buildIncomeItem(income, currencyFormat)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIncomeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
        backgroundColor: FintechColors.successColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildIncomeItem(Income income, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FintechColors.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForCategory(income.category),
            color: FintechColors.successColor,
          ),
        ),
        title: Text(
          income.source,
          style: FintechTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${income.category} • ${DateFormat.yMMMd().format(income.date)}',
          style: FintechTypography.bodySmall.copyWith(color: FintechColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(income.amount),
              style: FintechTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: FintechColors.successColor,
              ),
            ),
            if (income.isRecurring)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FintechColors.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recurring',
                  style: FintechTypography.caption.copyWith(
                    color: FintechColors.infoColor,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(income),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.work_outline;
      case 'freelance':
        return Icons.laptop_outlined;
      case 'business':
        return Icons.business_outlined;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.attach_money;
    }
  }

  void _showDeleteDialog(Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: Text('Delete income from ${income.source}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: FintechColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<IncomeProvider>(context, listen: false).deleteIncome(income.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Income deleted'),
              backgroundColor: FintechColors.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: FintechColors.errorColor,
            ),
          );
        }
      }
    }
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
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final income = Income(
        id: '',
        userId: authProvider.user?.id.toString() ?? '0',
        source: _sourceController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        isRecurring: _isRecurring,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await Provider.of<IncomeProvider>(context, listen: false).addIncome(income);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully'),
            backgroundColor: FintechColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add income: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: FintechColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Income', style: FintechTypography.h5),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Source Field
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  hintText: 'e.g., Freelance Project, Monthly Salary',
                  prefixIcon: Icon(Icons.source_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter source' : null,
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  if (double.tryParse(value) == null) return 'Please enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMd().format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Switch
              SwitchListTile(
                title: const Text('Recurring Income'),
                subtitle: const Text('This income repeats monthly'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional details',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FintechColors.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Add Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
