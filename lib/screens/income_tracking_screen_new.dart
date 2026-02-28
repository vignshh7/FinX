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
      builder: (context) => const IncomeFormSheet(),
    );
  }

  void _showEditIncomeDialog(Income income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeFormSheet(incomeToEdit: income),
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
                                ? incomeProvider.monthlyTotal > 0
                                    ? '${((netSavings / incomeProvider.monthlyTotal) * 100).toStringAsFixed(1)}% of income saved'
                                    : 'No income recorded'
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
              '${income.currency} ${currencyFormat.format(income.amount)}',
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
        onTap: () => _showIncomeOptions(income),
        onLongPress: () => _showDeleteDialog(income),
      ),
    );
  }

  void _showIncomeOptions(Income income) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: FintechColors.primaryColor),
              title: const Text('Edit Income'),
              onTap: () {
                Navigator.pop(context);
                _showEditIncomeDialog(income);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: FintechColors.errorColor),
              title: const Text('Delete Income'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(income);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
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

class IncomeFormSheet extends StatefulWidget {
  final Income? incomeToEdit;
  
  const IncomeFormSheet({super.key, this.incomeToEdit});

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
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

  bool get _isEditMode => widget.incomeToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Populate form with existing income data
      _sourceController.text = widget.incomeToEdit!.source;
      _amountController.text = widget.incomeToEdit!.amount.toString();
      _notesController.text = widget.incomeToEdit!.notes ?? '';
      _selectedCategory = widget.incomeToEdit!.category;
      _selectedDate = widget.incomeToEdit!.date;
      _isRecurring = widget.incomeToEdit!.isRecurring;
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      
      final income = Income(
        id: _isEditMode ? widget.incomeToEdit!.id : '',
        userId: authProvider.user?.id.toString() ?? '0',
        source: _sourceController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: 'INR', // Default currency
        date: _selectedDate,
        category: _selectedCategory,
        isRecurring: _isRecurring,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (_isEditMode) {
        await incomeProvider.updateIncome(income);
      } else {
        await incomeProvider.addIncome(income);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Income updated successfully' : 'Income added successfully'),
            backgroundColor: FintechColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditMode ? 'update' : 'add'} income: ${e.toString().replaceAll('Exception: ', '')}'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [FintechColors.successColor, FintechColors.successColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_isEditMode ? Icons.edit : Icons.add_circle_outline, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(_isEditMode ? 'Edit Income' : 'Add Income', style: FintechTypography.h5),
                    ],
                  ),
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

              // Category Selection with Visual Cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: FintechTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FintechColors.successColor
                                : (isDark ? FintechColors.darkSurface : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? FintechColors.successColor
                                  : (isDark ? FintechColors.borderColor : Colors.grey.shade300),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForCategory(cat),
                                color: isSelected ? Colors.white : cs.onSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : cs.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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

              // Recurring Switch with better design
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecurring
                      ? FintechColors.infoColor.withOpacity(0.1)
                      : (isDark ? FintechColors.darkSurface : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecurring
                        ? FintechColors.infoColor
                        : (isDark ? FintechColors.borderColor : Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: _isRecurring ? FintechColors.infoColor : cs.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recurring Income',
                            style: FintechTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This income repeats monthly',
                            style: FintechTypography.bodySmall.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                      activeColor: FintechColors.infoColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

              // Submit Button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSubmitting
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [FintechColors.successColor, FintechColors.successColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isSubmitting
                      ? []
                      : [
                          BoxShadow(
                            color: FintechColors.successColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isEditMode ? 'Updating Income...' : 'Adding Income...',
                              style: FintechTypography.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Update Income' : 'Add Income',
                              style: FintechTypography.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
