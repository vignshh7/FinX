import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fintech_colors.dart';
import '../../core/theme/fintech_typography.dart';
import '../../core/widgets/fintech_components.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/savings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../modern_receipt_scanner_screen.dart';
import '../expense_history_screen_new.dart';
import '../modern_ai_insights_screen_new.dart';
import '../subscription_tracker_screen_new.dart';
import '../income_tracking_screen_new.dart';
import '../budget_management_screen.dart';
import '../savings_goals_screen.dart';
import '../bill_reminders_screen.dart';
import '../data_management_screen.dart';
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
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    try {
      await Future.wait([
        expenseProvider.fetchExpenses(),
        incomeProvider.fetchIncomes(),
        subscriptionProvider.fetchSubscriptions(),
        savingsProvider.fetchSavingsGoals(),
        expenseProvider.fetchPrediction(),
        expenseProvider.fetchAlerts(),
      ]);
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
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final background = cs.background;
    final surfaceVariant = cs.surfaceVariant;
    final textPrimary = cs.onBackground;
    final textSecondary = cs.onBackground.withOpacity(0.7);
    final iconColor = theme.iconTheme.color;
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currencySymbol);
    final greeting = _getGreeting();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: cs.primary,
          backgroundColor: surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverToBoxAdapter(
                child: Container(
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Main Content
              _isLoading
                  ? SliverFillRemaining(
                      child: _buildLoadingSkeleton(),
                    )
                  : SliverToBoxAdapter(
                      child: _buildDashboardContent(
                        expenseProvider,
                        incomeProvider,
                        subscriptionProvider,
                        savingsProvider,
                        currencyFormat,
                      ),
                    ),
              // Bottom padding for navigation bar
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottomPadding + 120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    ExpenseProvider expenseProvider,
    IncomeProvider incomeProvider,
    SubscriptionProvider subscriptionProvider,
    SavingsProvider savingsProvider,
    NumberFormat currencyFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Overview Cards
        _buildFinancialOverview(
          expenseProvider,
          incomeProvider,
          subscriptionProvider,
          savingsProvider,
          currencyFormat,
        ),
        
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
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFinancialOverview(
    ExpenseProvider expenseProvider,
    IncomeProvider incomeProvider,
    SubscriptionProvider subscriptionProvider,
    SavingsProvider savingsProvider,
    NumberFormat currencyFormat,
  ) {
    final monthlySpent = expenseProvider.monthlyTotal;
    final monthlyIncome = incomeProvider.monthlyTotal;
    final subscriptionCost = subscriptionProvider.totalMonthlyCost;
    final savingsContributed = savingsProvider.monthlyContributedAmount;
    
    // Calculate budget based on income or use default
    final budget = monthlyIncome > 0 ? monthlyIncome : 5000.0;
    final remaining = monthlyIncome - monthlySpent - subscriptionCost - savingsContributed;
    final spentPercentage = budget > 0 ? (monthlySpent / budget).clamp(0.0, 1.0) : 0.0;
    final netSavings = monthlyIncome - monthlySpent;

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
                  'of ${currencyFormat.format(budget)} ${monthlyIncome > 0 ? "income" : "budget"}',
                  style: FintechTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                if (savingsContributed > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 12,
                        color: Colors.white.withOpacity(0.65),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currencyFormat.format(savingsContributed)} to savings',
                        style: FintechTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
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
                  title: 'Net Savings',
                  value: currencyFormat.format(netSavings),
                  icon: Icons.savings_outlined,
                  valueColor: netSavings >= 0 ? FintechColors.successColor : FintechColors.errorColor,
                  iconColor: FintechColors.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Income',
                  value: currencyFormat.format(monthlyIncome),
                  icon: Icons.trending_up,
                  iconColor: FintechColors.accentTeal,
                  showTrend: monthlyIncome > 0,
                  trendValue: 0.0, // Could calculate from previous month
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Additional Stats
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Subscriptions',
                  value: currencyFormat.format(subscriptionCost),
                  icon: Icons.subscriptions_outlined,
                  iconColor: FintechColors.accentOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Available',
                  value: currencyFormat.format(remaining > 0 ? remaining : 0),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: FintechColors.primaryBlue,
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
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(
            width: 110,
            child: QuickActionCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModernReceiptScannerScreen()),
              ),
              iconColor: const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: QuickActionCard(
              icon: Icons.add_circle_outline,
              label: 'Add Expense',
              onTap: () => _showAddExpenseModal(context),
              iconColor: FintechColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: QuickActionCard(
              icon: Icons.account_balance_outlined,
              label: 'Add Income',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeTrackingScreenNew()),
              ),
              iconColor: FintechColors.accentTeal,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
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
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: QuickActionCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Budget',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
              ),
              iconColor: FintechColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: QuickActionCard(
              icon: Icons.savings_outlined,
              label: 'Savings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
              ),
              iconColor: const Color(0xFF9C27B0),
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
              MaterialPageRoute(builder: (_) => const SubscriptionTrackerScreenNew()),
            ),
            iconColor: FintechColors.accentOrange,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget Management',
            subtitle: 'Set and track spending limits',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
            ),
            iconColor: FintechColors.accentGreen,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.savings_outlined,
            title: 'Savings Goals',
            subtitle: 'Track your financial goals',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
            ),
            iconColor: const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.notifications_active_outlined,
            title: 'Bill Management',
            subtitle: 'Never miss a payment',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillRemindersScreen()),
            ),
            iconColor: FintechColors.accentOrange,
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
            ),
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
            title: 'Data Management',
            subtitle: 'Export, import and backup your data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataManagementScreen()),
            ),
            iconColor: FintechColors.infoColor,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Manage app security settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            gradient: FintechColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Expense',
                          style: FintechTypography.h5.copyWith(color: cs.onSurface),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _storeController,
                  textInputAction: TextInputAction.next,
                  style: FintechTypography.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Store / Merchant',
                    hintText: 'e.g., Walmart, Amazon',
                    prefixIcon: Icon(Icons.storefront_outlined, color: FintechColors.primaryColor),
                    filled: true,
                    fillColor: isDark ? FintechColors.darkSurface : Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 20),

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
                      children: ExpenseCategory.allCategories.map((cat) {
                        final isSelected = _category == cat;
                        final categoryColor = ExpenseCategory.getColor(cat);
                        final categoryIcon = ExpenseCategory.getIcon(cat);
                        return InkWell(
                          onTap: () => setState(() => _category = cat),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? categoryColor
                                  : (isDark ? FintechColors.darkSurface : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? categoryColor
                                    : (isDark ? FintechColors.borderColor : Colors.grey.shade300),
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: categoryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryIcon,
                                  color: isSelected ? Colors.white : categoryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : cs.onSurface,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
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

                // Date Picker with better design
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? FintechColors.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? FintechColors.borderColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: FintechColors.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: FintechTypography.bodySmall.copyWith(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(_date),
                                style: FintechTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: _isSaving
                        ? LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade500],
                          )
                        : FintechColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSaving
                        ? []
                        : [
                            BoxShadow(
                              color: FintechColors.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 24),
                    label: Text(
                      _isSaving ? 'Adding Expense...' : 'Add Expense',
                      style: FintechTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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