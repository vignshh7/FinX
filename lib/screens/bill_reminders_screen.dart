import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/theme_provider.dart';
import '../providers/bill_reminder_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/bill_reminder_model.dart';
import '../models/expense_model.dart';
import 'savings_goals_screen.dart';

class BillRemindersScreen extends StatefulWidget {
  const BillRemindersScreen({super.key});

  @override
  State<BillRemindersScreen> createState() => _BillRemindersScreenState();
}

class _BillRemindersScreenState extends State<BillRemindersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBillData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBillData() async {
    try {
      final billProvider = Provider.of<BillReminderProvider>(context, listen: false);
      await billProvider.fetchBillReminders();
      if (!mounted) return;
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading bills: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    }
  }

  void _showAddBillDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBillReminderDialog(),
    );
  }

  void _showAddSavingsGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSavingsGoalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? FintechColors.primaryBackground : FintechColors.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(isDark),
              const SizedBox(height: 16),
              _buildTabBar(isDark),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingTab(),
                    _buildOverdueTab(),
                    _buildPaidTab(),
                    _buildAllTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBillDialog,
        backgroundColor: FintechColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? FintechColors.primaryPurple.withOpacity(0.1)
                        : FintechColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: FintechColors.primaryPurple,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Bill Management',
                  style: FintechTypography.h3.copyWith(
                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showAddSavingsGoalDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FintechColors.accentTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: FintechColors.accentTeal,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildOverviewCards(isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(bool isDark) {
    return Consumer<BillReminderProvider>(
      builder: (context, billProvider, _) {
        final upcomingCount = billProvider.upcomingBills.length;
        final overdueCount = billProvider.overdueBills.length;
        final totalAmount = billProvider.monthlyBillsAmount;
        final themeProvider = Provider.of<ThemeProvider>(context);
        final currencyFormat = NumberFormat.currency(symbol: themeProvider.currencySymbol);

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Due Soon',
                upcomingCount.toString(),
                FintechColors.warningColor,
                Icons.schedule,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                overdueCount.toString(),
                FintechColors.errorColor,
                Icons.warning,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Monthly Total',
                currencyFormat.format(totalAmount),
                FintechColors.primaryPurple,
                Icons.account_balance_wallet,
                isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: FintechTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: FintechTypography.caption.copyWith(
              color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: FintechColors.primaryPurple,
          boxShadow: [
            BoxShadow(
              color: FintechColors.primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
        labelStyle: FintechTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: FintechTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Overdue'),
          Tab(text: 'Paid'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Consumer<BillReminderProvider>(
      builder: (context, billProvider, _) {
        final bills = billProvider.upcomingBills;
        return _buildBillsList(bills, 'No upcoming bills', Icons.schedule);
      },
    );
  }

  Widget _buildOverdueTab() {
    return Consumer<BillReminderProvider>(
      builder: (context, billProvider, _) {
        final bills = billProvider.overdueBills;
        return _buildBillsList(bills, 'No overdue bills', Icons.warning);
      },
    );
  }

  Widget _buildPaidTab() {
    return Consumer<BillReminderProvider>(
      builder: (context, billProvider, _) {
        final bills = billProvider.paidBills;
        return _buildBillsList(bills, 'No paid bills', Icons.check_circle);
      },
    );
  }

  Widget _buildAllTab() {
    return Consumer<BillReminderProvider>(
      builder: (context, billProvider, _) {
        final bills = billProvider.bills;
        return _buildBillsList(bills, 'No bills found', Icons.receipt_long);
      },
    );
  }

  Widget _buildBillsList(List<BillReminder> bills, String emptyMessage, IconData emptyIcon) {
    if (bills.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            )),
            child: _buildBillCard(bill),
          ),
        );
      },
    );
  }

  Widget _buildBillCard(BillReminder bill) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currencySymbol);
    final urgencyColor = _getUrgencyColor(bill.urgency);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: urgencyColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        urgencyColor.withOpacity(0.15),
                        urgencyColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: urgencyColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      bill.category.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: FintechTypography.h6.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (bill.description != null && bill.description!.isNotEmpty)
                        Text(
                          bill.description!,
                          style: FintechTypography.bodySmall.copyWith(
                            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bill.category.displayName,
                              style: FintechTypography.caption.copyWith(
                                color: urgencyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(bill.amount),
                      style: FintechTypography.h5.copyWith(
                        color: urgencyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: urgencyColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bill.urgency.displayName,
                        style: FintechTypography.caption.copyWith(
                          color: urgencyColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? FintechColors.primaryBackground.withOpacity(0.5)
                    : FintechColors.lightBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: urgencyColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                    style: FintechTypography.bodySmall.copyWith(
                      color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDaysText(bill.daysUntilDue, bill.isPaid),
                      style: FintechTypography.caption.copyWith(
                        color: urgencyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!bill.isPaid) ...[
                  ElevatedButton.icon(
                    onPressed: () => _markBillAsPaid(bill),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FintechColors.successColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _editBill(bill),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FintechColors.primaryPurple,
                    side: BorderSide(color: FintechColors.primaryPurple, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteBill(bill),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FintechColors.errorColor,
                    side: BorderSide(color: FintechColors.errorColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(BillUrgency urgency) {
    switch (urgency) {
      case BillUrgency.paid:
        return FintechColors.successColor;
      case BillUrgency.overdue:
        return FintechColors.errorColor;
      case BillUrgency.dueToday:
        return FintechColors.warningColor;
      case BillUrgency.dueSoon:
        return FintechColors.warningColor.withOpacity(0.8);
      case BillUrgency.normal:
        return FintechColors.primaryPurple;
    }
  }

  String _getDaysText(int daysUntilDue, bool isPaid) {
    if (isPaid) return 'Paid';
    if (daysUntilDue < 0) return '${daysUntilDue.abs()} days overdue';
    if (daysUntilDue == 0) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }

  String _mapBillCategoryToExpenseCategory(BillCategory category) {
    switch (category) {
      case BillCategory.utilities:
        return 'Utilities';
      case BillCategory.housing:
        return 'Housing';
      case BillCategory.insurance:
        return 'Finance';
      case BillCategory.subscriptions:
        return 'Entertainment';
      case BillCategory.loans:
        return 'Finance';
      case BillCategory.creditCards:
        return 'Finance';
      case BillCategory.taxes:
        return 'Finance';
      case BillCategory.healthcare:
        return 'Health';
      case BillCategory.transportation:
        return 'Transport';
      case BillCategory.education:
        return 'Education';
      case BillCategory.entertainment:
        return 'Entertainment';
      case BillCategory.other:
        return 'Other';
    }
  }

  void _markBillAsPaid(BillReminder bill) async {
    final billProvider =
        Provider.of<BillReminderProvider>(context, listen: false);
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Call provider — it instantly removes bill from upcoming and re-fetches
    final success = await billProvider.markBillAsPaid(bill.id!);

    // 2. Switch to Paid tab so user can see the bill there
    if (mounted) _tabController.animateTo(2);

    // 3. Record as expense
    if (success) {
      final expense = Expense(
        userId: authProvider.user?.id ?? 0,
        store: bill.title,
        amount: bill.amount,
        category: _mapBillCategoryToExpenseCategory(bill.category),
        date: DateTime.now(),
      );
      final expenseAdded = await expenseProvider.addExpense(expense);
      if (expenseAdded) {
        await expenseProvider.fetchExpenses(forceRefresh: true);
      }
    }

    // 4. Show result snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${bill.title} marked as paid!'
                : 'Failed to update bill. Try again.',
          ),
          backgroundColor:
              success ? FintechColors.successColor : FintechColors.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editBill(BillReminder bill) {
    showDialog(
      context: context,
      builder: (context) => EditBillReminderDialog(bill: bill),
    );
  }

  Future<void> _confirmDeleteBill(BillReminder bill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Delete "${bill.title}"? This cannot be undone.'),
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

    if (shouldDelete != true || bill.id == null) return;
    final billProvider = Provider.of<BillReminderProvider>(context, listen: false);
    final success = await billProvider.deleteBillReminder(bill.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Bill deleted.' : 'Failed to delete bill.'),
        backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                    ? FintechColors.primaryPurple.withOpacity(0.1)
                    : FintechColors.primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 48,
                color: FintechColors.primaryPurple.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: FintechTypography.h5.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first bill reminder to get started',
              style: FintechTypography.bodyMedium.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Add Bill Dialog
class AddBillReminderDialog extends StatefulWidget {
  const AddBillReminderDialog({super.key});

  @override
  State<AddBillReminderDialog> createState() => _AddBillReminderDialogState();
}

class _AddBillReminderDialogState extends State<AddBillReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  BillCategory _selectedCategory = BillCategory.utilities;
  BillPriority _selectedPriority = BillPriority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isRecurring = false;
  BillFrequency _selectedFrequency = BillFrequency.oneTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveBill() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final billProvider = Provider.of<BillReminderProvider>(context, listen: false);

    final bill = BillReminder(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      amount: double.parse(_amountController.text),
      dueDate: _dueDate,
      category: _selectedCategory,
      frequency: _selectedFrequency,
      priority: _selectedPriority,
      isRecurring: _isRecurring,
      status: BillStatus.pending,
      createdAt: DateTime.now(),
    );

    final success = await billProvider.addBillReminder(bill);
    
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Bill reminder added!' : 'Failed to add bill'),
          backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
        ),
      );
    } else {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? FintechColors.cardBackground : FintechColors.lightCardBackground,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Bill Reminder',
                  style: FintechTypography.h4.copyWith(
                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Bill Title',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a bill title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category
                DropdownButtonFormField<BillCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: BillCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(category.displayName),
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
                // Priority Dropdown
                DropdownButtonFormField<BillPriority>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: BillPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Due Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _dueDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_dueDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recurring Switch
                SwitchListTile(
                  title: Text(
                    'Recurring Bill',
                    style: FintechTypography.bodyMedium.copyWith(
                      color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically create future reminders',
                    style: FintechTypography.bodySmall.copyWith(
                      color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                    ),
                  ),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!_isRecurring) {
                        _selectedFrequency = BillFrequency.oneTime;
                      } else if (_selectedFrequency == BillFrequency.oneTime) {
                        _selectedFrequency = BillFrequency.monthly;
                      }
                    });
                  },
                  activeColor: FintechColors.primaryPurple,
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FintechColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add Bill'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Edit Bill Dialog (simplified version)
class EditBillReminderDialog extends StatefulWidget {
  final BillReminder bill;
  
  const EditBillReminderDialog({super.key, required this.bill});

  @override
  State<EditBillReminderDialog> createState() => _EditBillReminderDialogState();
}

class _EditBillReminderDialogState extends State<EditBillReminderDialog> {
  late TextEditingController _amountController;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.bill.amount.toString());
    _dueDate = widget.bill.dueDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateBill() async {
    final billProvider = Provider.of<BillReminderProvider>(context, listen: false);
    
    final updatedBill = widget.bill.copyWith(
      amount: double.parse(_amountController.text),
      dueDate: _dueDate,
      frequency: BillFrequency.oneTime,
      isRecurring: false,
      updatedAt: DateTime.now(),
    );

    final success = await billProvider.updateBillReminder(updatedBill);
    
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Bill updated successfully!' : 'Failed to update bill'),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Bill',
              style: FintechTypography.h4.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.bill.title,
              style: FintechTypography.bodyMedium.copyWith(
                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Due Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _dueDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_dueDate),
                ),
              ),
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
                  onPressed: _updateBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FintechColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}