import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fintech_colors.dart';
import '../../core/theme/fintech_typography.dart';
import '../../core/widgets/fintech_components.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../modern_receipt_scanner_screen.dart';
import '../expense_history_screen.dart';
import '../modern_ai_insights_screen.dart';
import '../subscription_tracker_screen.dart';
import '../income_tracking_screen.dart';
import '../settings_screen.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  bool _isLoading = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    try {
      await expenseProvider.fetchExpenses();
      await expenseProvider.fetchPrediction();
      await expenseProvider.fetchAlerts();
    } catch (e) {
      // Handle error silently for now
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final background = cs.background;
    final surfaceVariant = cs.surfaceVariant;
    final textPrimary = cs.onBackground;
    final textSecondary = cs.onBackground.withOpacity(0.7);
    final iconColor = theme.iconTheme.color;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final greeting = _getGreeting();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: cs.primary,
          backgroundColor: surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                        // Modern App Bar
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                background,
                                isDark ? surface : surfaceVariant,
                              ],
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                greeting,
                                style: FintechTypography.bodyLarge.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.user?.name ?? 'User',
                                style: FintechTypography.h3.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_outlined, color: iconColor),
                              onPressed: () => _showNotifications(context),
                            ),
                            IconButton(
                              icon: Icon(Icons.person_outline, color: iconColor),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                        // Main Content
                        Expanded(
                          child: _isLoading
                              ? _buildLoadingSkeleton()
                              : _buildDashboardContent(expenseProvider, currencyFormat),
                        ),
                        SizedBox(height: bottomPadding + 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ExpenseProvider expenseProvider, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Overview Cards
        _buildFinancialOverview(expenseProvider, currencyFormat),
        
        const SizedBox(height: 24),
        
        // Quick Actions
        const SectionHeader(title: 'Quick Actions'),
        _buildQuickActions(),
        
        const SizedBox(height: 24),
        
        // Finance Section
        const SectionHeader(
          title: 'Finance',
          actionText: 'View All',
          actionIcon: Icons.arrow_forward_ios,
        ),
        _buildFinanceSection(),
        
        const SizedBox(height: 24),
        
        // Analytics Section
        const SectionHeader(title: 'Analytics'),
        _buildAnalyticsSection(expenseProvider, currencyFormat),
        
        const SizedBox(height: 24),
        
        // Utilities Section
        const SectionHeader(title: 'Utilities'),
        _buildUtilitiesSection(),
        
        const SizedBox(height: 100), // Bottom padding for navigation
      ],
    );
  }

  Widget _buildFinancialOverview(ExpenseProvider expenseProvider, NumberFormat currencyFormat) {
    final monthlySpent = expenseProvider.monthlyTotal;
    final budget = 5000.0; // This should come from user preferences
    final remaining = budget - monthlySpent;
    final spentPercentage = (monthlySpent / budget).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main Balance Card
          FintechCard(
            gradient: FintechColors.primaryGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Month',
                      style: FintechTypography.labelLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currencyFormat.format(monthlySpent),
                  style: FintechTypography.currencyLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'of ${currencyFormat.format(budget)} budget',
                  style: FintechTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress bar
                LinearProgressIndicator(
                  value: spentPercentage,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    spentPercentage > 0.8 ? FintechColors.warningColor : Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Remaining',
                  value: currencyFormat.format(remaining),
                  icon: Icons.account_balance_wallet_outlined,
                  valueColor: remaining >= 0 ? FintechColors.successColor : FintechColors.errorColor,
                  iconColor: FintechColors.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Income',
                  value: currencyFormat.format(8000), // Mock data
                  icon: Icons.trending_up,
                  iconColor: FintechColors.accentTeal,
                  showTrend: true,
                  trendValue: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(
            width: 100,
            child: QuickActionCard(
              icon: Icons.camera_alt_outlined,
              label: 'Scan Receipt',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModernReceiptScannerScreen()),
              ),
              gradient: FintechColors.primaryGradient,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: QuickActionCard(
              icon: Icons.add_circle_outline,
              label: 'Add Expense',
              onTap: () => _showAddExpenseModal(context),
              iconColor: FintechColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: QuickActionCard(
              icon: Icons.account_balance_outlined,
              label: 'Add Income',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeTrackingScreen()),
              ),
              iconColor: FintechColors.accentTeal,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: QuickActionCard(
              icon: Icons.analytics_outlined,
              label: 'Insights',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModernAIInsightsScreen()),
              ),
              iconColor: FintechColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FeatureCard(
            icon: Icons.history,
            title: 'Transaction History',
            subtitle: 'View all your expenses and income',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
            ),
            iconColor: FintechColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.subscriptions_outlined,
            title: 'Subscriptions',
            subtitle: 'Manage recurring payments',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionTrackerScreen()),
            ),
            iconColor: FintechColors.accentOrange,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.savings_outlined,
            title: 'Budget Planning',
            subtitle: 'Set and track spending limits',
            onTap: () => _showBudgetModal(context),
            iconColor: FintechColors.accentGreen,
            isComingSoon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(ExpenseProvider expenseProvider, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FeatureCard(
            icon: Icons.psychology_outlined,
            title: 'AI Insights',
            subtitle: 'Smart spending analysis and tips',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ModernAIInsightsScreen()),
            ),
            gradient: LinearGradient(
              colors: [FintechColors.primaryPurple.withOpacity(0.1), Colors.transparent],
            ),
            iconColor: FintechColors.primaryPurple,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.bar_chart,
            title: 'Spending Reports',
            subtitle: 'Detailed financial reports',
            onTap: () => _showReportsModal(context),
            iconColor: FintechColors.accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          FeatureCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Export Data',
            subtitle: 'Backup and export your data',
            onTap: () => _showExportModal(context),
            iconColor: FintechColors.infoColor,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Manage app security settings',
            onTap: () => _showSecurityModal(context),
            iconColor: FintechColors.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ShimmerCard(width: double.infinity, height: 140),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerCard(width: double.infinity, height: 100)),
              SizedBox(width: 12),
              Expanded(child: ShimmerCard(width: double.infinity, height: 100)),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const ShimmerCard(width: double.infinity, height: 80),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FintechColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: FintechTypography.h4.copyWith(color: FintechColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'No new notifications',
              style: FintechTypography.bodyMedium.copyWith(color: FintechColors.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddExpenseSheet(),
    );
  }

  void _showBudgetModal(BuildContext context) {
    // TODO: Implement budget modal
  }

  void _showReportsModal(BuildContext context) {
    // TODO: Implement reports modal
  }

  void _showExportModal(BuildContext context) {
    // TODO: Implement export modal
  }

  void _showSecurityModal(BuildContext context) {
    // TODO: Implement security modal
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _storeController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = ExpenseCategory.other;
  bool _isSaving = false;

  @override
  void dispose() {
    _storeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final amount = double.parse(_amountController.text.trim());
    final expense = Expense(
      userId: authProvider.user?.id ?? 1,
      store: _storeController.text.trim(),
      amount: amount,
      category: _category,
      date: _date,
    );

    final success = await expenseProvider.addExpense(expense);
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(expenseProvider.error ?? 'Failed to add expense')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Text(
                  'Add Expense',
                  style: FintechTypography.h4.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _storeController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Store / Merchant',
                    hintText: 'e.g., Grocery Store',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g., 499.99',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ExpenseCategory.allCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}