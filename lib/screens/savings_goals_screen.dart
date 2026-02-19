import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/theme_provider.dart';
import '../providers/savings_provider.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  late int _reportYear;
  late int _reportMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reportYear = now.year;
    _reportMonth = now.month;
    _loadSavingsData();
  }

  Future<void> _loadSavingsData() async {
    try {
      final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
      await Future.wait([
        savingsProvider.fetchSavingsGoals(),
        savingsProvider.fetchMonthlyReport(year: _reportYear, month: _reportMonth),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading savings data: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSavingsGoalDialog(),
    );
  }

  void _showContributeDialog(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AddContributionDialog(goal: goal),
    );
  }

  Future<void> _markGoalAsAchieved(SavingsGoal goal) async {
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    if (goal.isCompleted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal is already achieved.'),
          backgroundColor: FintechColors.successColor,
        ),
      );
      return;
    }

    final updatedGoal = goal.copyWith(
      isCompleted: true,
      currentAmount: goal.targetAmount,
      updatedAt: DateTime.now(),
    );
    final success = await savingsProvider.updateSavingsGoal(updatedGoal);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Goal marked as achieved.' : 'Failed to update goal.'),
        backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
      ),
    );
  }

  Future<void> _confirmDeleteGoal(SavingsGoal goal) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.title}"? This cannot be undone.'),
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

    if (shouldDelete != true || goal.id == null) return;
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    final success = await savingsProvider.deleteSavingsGoal(goal.id!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Goal deleted.' : 'Failed to delete goal.'),
        backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
      ),
    );
  }

  Future<void> _pickReportMonth() async {
    final initialDate = DateTime(_reportYear, _reportMonth, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Select month',
    );

    if (picked != null) {
      setState(() {
        _reportYear = picked.year;
        _reportMonth = picked.month;
      });
      final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
      await savingsProvider.fetchMonthlyReport(year: _reportYear, month: _reportMonth);
    }
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
                  _buildMonthlyReportCard(currencyFormat, isDark),
                  const SizedBox(height: 20),
                  _buildGoalsList(currencyFormat, isDark),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        backgroundColor: FintechColors.accentTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
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
          'Savings Goals',
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
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, _) {
        final totalTarget = savingsProvider.totalTargetAmount;
        final totalSaved = savingsProvider.totalSavedAmount;
        final totalGoals = savingsProvider.goals.length;
        final completedGoals = savingsProvider.completedGoals.length;

        return FintechCard(
          gradient: LinearGradient(
            colors: [
              FintechColors.accentTeal,
              FintechColors.accentTeal.withOpacity(0.8),
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
                      Icons.savings,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Saved',
                            style: FintechTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            currencyFormat.format(totalSaved),
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
                
                Row(
                  children: [
                    Expanded(
                      child: _buildSavingsStat(
                        'Goals',
                        '$completedGoals/$totalGoals',
                        Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _buildSavingsStat(
                        'Target',
                        currencyFormat.format(totalTarget),
                        Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _buildSavingsStat(
                        'Progress',
                        '${((totalTarget > 0 ? totalSaved / totalTarget : 0) * 100).toInt()}%',
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavingsStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: FintechTypography.h5.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportCard(NumberFormat currencyFormat, bool isDark) {
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, _) {
        final report = savingsProvider.monthlyReport;
        if (report == null) {
          return FintechCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    color: FintechColors.accentTeal,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Monthly savings report updates after your first contribution.',
                      style: FintechTypography.bodySmall.copyWith(
                        color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final year = (report['year'] as num?)?.toInt() ?? _reportYear;
        final month = (report['month'] as num?)?.toInt() ?? _reportMonth;
        final reportDate = DateTime(year, month, 1);
        final totalContributed = _toDouble(report['total_contributed']);
        final totalRemaining = _toDouble(report['total_remaining']);
        final goals = (report['goals'] as List?) ?? [];
        final totalFlow = totalContributed + totalRemaining;

        return FintechCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      color: FintechColors.accentTeal,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Monthly Savings • ${DateFormat('MMMM yyyy').format(reportDate)}',
                        style: FintechTypography.h5.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _pickReportMonth,
                      icon: const Icon(Icons.calendar_month),
                      color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                      tooltip: 'Pick month',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportStat(
                        'Contributed',
                        currencyFormat.format(totalContributed),
                        FintechColors.accentTeal,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildReportStat(
                        'Remaining',
                        currencyFormat.format(totalRemaining),
                        FintechColors.warningColor,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (totalFlow > 0) ...[
                  _buildMonthlyFlowBar(
                    totalContributed,
                    totalRemaining,
                    isDark,
                  ),
                ],
                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...goals.take(5).map((goal) {
                    final title = goal['title']?.toString() ?? 'Goal';
                    final contributed = _toDouble(goal['contributed']);
                    final remaining = _toDouble(goal['remaining']);
                    final total = contributed + remaining;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: FintechTypography.bodySmall.copyWith(
                                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormat.format(contributed),
                                style: FintechTypography.caption.copyWith(
                                  color: FintechColors.accentTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currencyFormat.format(remaining),
                                style: FintechTypography.caption.copyWith(
                                  color: FintechColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildGoalMiniBar(
                            contributed,
                            total,
                            isDark,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyFlowBar(double contributed, double remaining, bool isDark) {
    final total = contributed + remaining;
    final contributedFlex = total > 0 ? (contributed / total * 100).round() : 0;
    final remainingFlex = total > 0 ? (remaining / total * 100).round() : 0;

    final safeContributed = contributedFlex == 0 && contributed > 0 ? 1 : contributedFlex;
    final safeRemaining = remainingFlex == 0 && remaining > 0 ? 1 : remainingFlex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Expanded(
            flex: safeContributed == 0 ? 1 : safeContributed,
            child: Container(
              height: 8,
              color: FintechColors.accentTeal,
            ),
          ),
          Expanded(
            flex: safeRemaining == 0 ? 1 : safeRemaining,
            child: Container(
              height: 8,
              color: isDark
                  ? FintechColors.borderColor
                  : FintechColors.borderColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalMiniBar(double contributed, double total, bool isDark) {
    final progress = total > 0 ? (contributed / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isDark
            ? FintechColors.borderColor
            : FintechColors.borderColor.withOpacity(0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: FintechColors.accentTeal,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: FintechTypography.h5.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Widget _buildGoalsList(NumberFormat currencyFormat, bool isDark) {
    return Consumer<SavingsProvider>(
      builder: (context, savingsProvider, _) {
        if (savingsProvider.isLoading) {
          return _buildLoadingSkeleton();
        }

        if (savingsProvider.goals.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Goals',
              style: FintechTypography.h4.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...savingsProvider.goals.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGoalCard(goal, currencyFormat, isDark),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, NumberFormat currencyFormat, bool isDark) {
    final progressPercentage = goal.progressPercentage;
    final daysRemaining = goal.daysRemaining;
    final statusColor = _getStatusColor(goal.status);
    final isCompleted = goal.status == SavingsGoalStatus.completed;

    return FintechCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          isCompleted ? '🏆' : goal.category.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: FintechTypography.h5.copyWith(
                              color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (goal.description != null)
                            Text(
                              goal.description!,
                              style: FintechTypography.bodySmall.copyWith(
                                color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        goal.status.displayName,
                        style: FintechTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDeleteGoal(goal),
                      icon: const Icon(Icons.delete_outline),
                      color: FintechColors.errorColor,
                      tooltip: 'Delete goal',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (isCompleted) ...[
                  // Completed celebration banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FintechColors.successColor.withOpacity(0.15),
                          FintechColors.accentTeal.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FintechColors.successColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: FintechColors.successColor, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'Goal Achieved!',
                          style: FintechTypography.bodyMedium.copyWith(
                            color: FintechColors.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyFormat.format(goal.currentAmount)} saved',
                          style: FintechTypography.h6.copyWith(
                            color: FintechColors.successColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Full progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 8,
                        backgroundColor: FintechColors.successColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(FintechColors.successColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markGoalAsAchieved(goal),
                      icon: const Icon(Icons.emoji_events, size: 18),
                      label: const Text('Mark as Achieved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FintechColors.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(goal.currentAmount),
                        style: FintechTypography.h6.copyWith(
                          color: FintechColors.accentTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(goal.targetAmount),
                        style: FintechTypography.bodyMedium.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark
                          ? FintechColors.borderColor
                          : FintechColors.borderColor.withOpacity(0.3),
                    ),
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildGoalStat(
                          'Progress',
                          '${(progressPercentage * 100).toInt()}%',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildGoalStat(
                          'Days Left',
                          daysRemaining > 0 ? '$daysRemaining' : 'Overdue',
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildGoalStat(
                          'Monthly Need',
                          currencyFormat.format(goal.requiredMonthlyContribution),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showContributeDialog(goal),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Contribute'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FintechColors.accentTeal,
                            side: BorderSide(color: FintechColors.accentTeal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showGoalDetails(goal),
                          icon: const Icon(Icons.info, size: 18),
                          label: const Text('Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: FintechTypography.bodySmall.copyWith(
            color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SavingsGoalStatus status) {
    switch (status) {
      case SavingsGoalStatus.completed:
        return FintechColors.successColor;
      case SavingsGoalStatus.nearCompletion:
        return FintechColors.accentTeal;
      case SavingsGoalStatus.onTrack:
        return FintechColors.primaryColor;
      case SavingsGoalStatus.urgent:
        return FintechColors.warningColor;
      case SavingsGoalStatus.overdue:
        return FintechColors.errorColor;
      case SavingsGoalStatus.active:
        return FintechColors.primaryPurple;
    }
  }

  void _showGoalDetails(SavingsGoal goal) {
    // Navigate to goal details screen
    Navigator.of(context).pushNamed('/goal-details', arguments: goal);
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: FintechColors.borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
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
              Icons.savings_outlined,
              size: 64,
              color: isDark 
                  ? FintechColors.textSecondary
                  : FintechColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Savings Goals Yet',
              style: FintechTypography.h5.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first savings goal to start building your future',
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

// Add Goal Dialog
class AddSavingsGoalDialog extends StatefulWidget {
  const AddSavingsGoalDialog({super.key});

  @override
  State<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends State<AddSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  SavingsGoalCategory _selectedCategory = SavingsGoalCategory.general;
  SavingsGoalPriority _selectedPriority = SavingsGoalPriority.medium;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    final goal = SavingsGoal(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      targetAmount: double.parse(_amountController.text),
      targetDate: _targetDate,
      createdAt: DateTime.now(),
      category: _selectedCategory,
      priority: _selectedPriority,
    );

    final success = await savingsProvider.addSavingsGoal(goal);
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Goal created successfully!' : 'Failed to create goal'),
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
                  'Create Savings Goal',
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
                    labelText: 'Goal Title',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal title';
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
                    labelText: 'Target Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter target amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<SavingsGoalCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: SavingsGoalCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
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
                
                // Target Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _targetDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Target Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_targetDate),
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
                      onPressed: _saveGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FintechColors.accentTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Goal'),
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

// Add Contribution Dialog
class AddContributionDialog extends StatefulWidget {
  final SavingsGoal goal;
  
  const AddContributionDialog({super.key, required this.goal});

  @override
  State<AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  SavingsContributionType _type = SavingsContributionType.manual;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveContribution() async {
    if (!_formKey.currentState!.validate()) return;

    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    final contribution = SavingsContribution(
      goalId: widget.goal.id!,
      amount: double.parse(_amountController.text),
      date: DateTime.now(),
      note: _noteController.text.isEmpty ? null : _noteController.text,
      type: _type,
    );

    final success = await savingsProvider.addContribution(contribution);
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Contribution added successfully!' : 'Failed to add contribution'),
          backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currencySymbol);

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
                'Add Contribution',
                style: FintechTypography.h4.copyWith(
                  color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.goal.title,
                style: FintechTypography.bodyMedium.copyWith(
                  color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Progress Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FintechColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: FintechTypography.caption.copyWith(
                            color: FintechColors.accentTeal,
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.goal.currentAmount),
                          style: FintechTypography.bodyMedium.copyWith(
                            color: FintechColors.accentTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining',
                          style: FintechTypography.caption.copyWith(
                            color: FintechColors.accentTeal,
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.goal.remainingAmount),
                          style: FintechTypography.bodyMedium.copyWith(
                            color: FintechColors.accentTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  labelText: 'Contribution Amount',
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
              const SizedBox(height: 16),
              
              // Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    onPressed: _saveContribution,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FintechColors.accentTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Contribution'),
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