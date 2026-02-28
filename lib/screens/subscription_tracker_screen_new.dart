import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/subscription_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/subscription_model.dart';
import '../models/expense_model.dart';

class SubscriptionTrackerScreenNew extends StatefulWidget {
  const SubscriptionTrackerScreenNew({super.key});

  @override
  State<SubscriptionTrackerScreenNew> createState() => _SubscriptionTrackerScreenNewState();
}

class _SubscriptionTrackerScreenNewState extends State<SubscriptionTrackerScreenNew> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: FintechColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubscriptionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
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
                    // Summary Card
                    FintechCard(
                      gradient: LinearGradient(
                        colors: [FintechColors.primaryBlue, FintechColors.primaryPurple],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monthly Total',
                                style: FintechTypography.labelLarge.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Icon(Icons.subscriptions_outlined, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(subscriptionProvider.totalMonthlyCost),
                            style: FintechTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${subscriptionProvider.subscriptions.length} active subscriptions',
                            style: FintechTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Yearly Cost',
                            value: currencyFormat.format(subscriptionProvider.totalMonthlyCost * 12),
                            icon: Icons.calendar_today,
                            iconColor: FintechColors.warningColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatsCard(
                            title: 'Avg/Month',
                            value: subscriptionProvider.subscriptions.isEmpty
                                ? currencyFormat.format(0)
                                : currencyFormat.format(
                                    subscriptionProvider.totalMonthlyCost /
                                        subscriptionProvider.subscriptions.length),
                            icon: Icons.analytics_outlined,
                            iconColor: FintechColors.infoColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Subscriptions List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Subscriptions', style: FintechTypography.h5),
                        if (subscriptionProvider.subscriptions.isNotEmpty)
                          Text(
                            '${subscriptionProvider.subscriptions.length} services',
                            style: FintechTypography.bodyMedium.copyWith(
                              color: FintechColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subscriptions List
                    if (subscriptionProvider.subscriptions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.subscriptions_outlined,
                                size: 64,
                                color: FintechColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subscriptions tracked',
                                style: FintechTypography.bodyLarge.copyWith(
                                  color: FintechColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first subscription to start tracking',
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
                      ...subscriptionProvider.subscriptions
                          .map((sub) => _buildSubscriptionCard(sub, currencyFormat)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubscriptionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
        backgroundColor: FintechColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription subscription, NumberFormat currencyFormat) {
    final daysUntilRenewal = subscription.renewalDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntilRenewal <= 7 && daysUntilRenewal >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isUpcoming ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isUpcoming
              ? Border.all(color: FintechColors.warningColor, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: FintechColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForSubscription(subscription.name),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          style: FintechTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subscription.frequency.toUpperCase(),
                          style: FintechTypography.bodySmall.copyWith(
                            color: FintechColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(subscription.amount),
                        style: FintechTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: FintechColors.primaryBlue,
                        ),
                      ),
                      Text(
                        currencyFormat.format(subscription.monthlyAmount) + '/mo',
                        style: FintechTypography.caption.copyWith(
                          color: FintechColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _showDeleteDialog(subscription),
                    color: FintechColors.errorColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? FintechColors.warningColor.withOpacity(0.1)
                      : FintechColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isUpcoming ? FintechColors.warningColor : FintechColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUpcoming
                          ? 'Renews in $daysUntilRenewal days'
                          : 'Next: ${DateFormat.yMMMd().format(subscription.renewalDate)}',
                      style: FintechTypography.bodySmall.copyWith(
                        color: isUpcoming ? FintechColors.warningColor : FintechColors.textSecondary,
                        fontWeight: isUpcoming ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForSubscription(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('netflix') || lowerName.contains('spotify') ||
        lowerName.contains('youtube') || lowerName.contains('music')) {
      return Icons.play_circle_outline;
    } else if (lowerName.contains('gym') || lowerName.contains('fitness')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('cloud') || lowerName.contains('storage')) {
      return Icons.cloud_outlined;
    } else if (lowerName.contains('app') || lowerName.contains('software')) {
      return Icons.apps;
    }
    return Icons.subscriptions_outlined;
  }

  void _showDeleteDialog(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Remove ${subscription.name}?'),
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
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .deleteSubscription(subscription.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription deleted'),
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

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedFrequency = 'monthly';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subscription = Subscription(
        userId: authProvider.user?.id ?? 0,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        renewalDate: _selectedDate,
      );

      await Provider.of<SubscriptionProvider>(context, listen: false)
          .addSubscription(subscription);

      // If renewal date is today or already past, record as an expense
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final renewalDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      if (!renewalDay.isAfter(today)) {
        final expenseProvider =
            Provider.of<ExpenseProvider>(context, listen: false);
        final expense = Expense(
          userId: authProvider.user?.id ?? 0,
          store: _nameController.text.trim(),
          amount: _selectedFrequency == 'yearly'
              ? double.parse(_amountController.text) / 12
              : double.parse(_amountController.text),
          category: 'Entertainment',
          date: now,
        );
        await expenseProvider.addExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription added'),
            backgroundColor: FintechColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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
                  Text('Add Subscription', style: FintechTypography.h5),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g., Netflix, Spotify',
                  prefixIcon: Icon(Icons.subscriptions_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Billing Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) => setState(() => _selectedFrequency = value!),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next Renewal Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMd().format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FintechColors.primaryBlue,
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
                    : const Text(
                        'Add Subscription',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
