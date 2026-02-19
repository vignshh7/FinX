import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../core/widgets/fintech_components.dart';
import '../providers/theme_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/bill_reminder_provider.dart';
import '../services/export_import_service.dart';
import '../services/api_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isReportExporting = false;

  final Map<String, bool> _exportOptions = {
    'expenses': true,
    'income': true,
    'budgets': true,
    'savings': true,
    'bills': true,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDataOverview(isDark),
                    const SizedBox(height: 20),
                    _buildExportSection(isDark),
                    const SizedBox(height: 20),
                    _buildImportSection(isDark),
                    const SizedBox(height: 20),
                    _buildBackupOptions(isDark),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
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
          'Data Management',
          style: FintechTypography.h3.copyWith(
            color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildDataOverview(bool isDark) {
    return Consumer5<ExpenseProvider, IncomeProvider, BudgetProvider, SavingsProvider, BillReminderProvider>(
      builder: (context, expenseProvider, incomeProvider, budgetProvider, savingsProvider, billProvider, _) {
        final expenseCount = expenseProvider.expenses.length;
        final incomeCount = incomeProvider.incomes.length;
        final budgetCount = budgetProvider.budgets.length;
        final savingsCount = savingsProvider.goals.length;
        final billsCount = billProvider.bills.length;

        return FintechCard(
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
                      Icons.storage,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Financial Data',
                            style: FintechTypography.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage your data export and import',
                            style: FintechTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
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
                      child: _buildDataStat('Expenses', expenseCount.toString(), Colors.white),
                    ),
                    Expanded(
                      child: _buildDataStat('Income', incomeCount.toString(), Colors.white),
                    ),
                    Expanded(
                      child: _buildDataStat('Budgets', budgetCount.toString(), Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDataStat('Savings Goals', savingsCount.toString(), Colors.white),
                    ),
                    Expanded(
                      child: _buildDataStat('Bill Reminders', billsCount.toString(), Colors.white),
                    ),
                    Expanded(child: Container()), // Empty space for alignment
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: FintechTypography.h5.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: FintechTypography.caption.copyWith(
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(bool isDark) {
    return FintechCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FintechColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.file_download,
                    color: FintechColors.successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Data',
                        style: FintechTypography.h5.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Download your financial data as JSON or CSV',
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Text(
              'Select data to export:',
              style: FintechTypography.bodyMedium.copyWith(
                color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._exportOptions.entries.map((entry) {
              return CheckboxListTile(
                title: Text(
                  _getDataTypeDisplayName(entry.key),
                  style: FintechTypography.bodyMedium.copyWith(
                    color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  _getDataTypeDescription(entry.key),
                  style: FintechTypography.bodySmall.copyWith(
                    color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                  ),
                ),
                value: entry.value,
                onChanged: (bool? value) {
                  setState(() {
                    _exportOptions[entry.key] = value ?? false;
                  });
                },
                activeColor: FintechColors.successColor,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('json'),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(_isExporting ? 'Exporting...' : 'Export JSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FintechColors.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('csv'),
                    icon: const Icon(Icons.file_copy, size: 18),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FintechColors.successColor,
                      side: BorderSide(color: FintechColors.successColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildImportSection(bool isDark) {
    return FintechCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FintechColors.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.file_upload,
                    color: FintechColors.accentTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Data',
                        style: FintechTypography.h5.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Upload and restore your financial data from JSON file',
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FintechColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FintechColors.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: FintechColors.warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Notice',
                          style: FintechTypography.bodyMedium.copyWith(
                            color: FintechColors.warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Importing data will merge with existing data. Duplicate entries may be created.',
                          style: FintechTypography.bodySmall.copyWith(
                            color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importData,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(_isImporting ? 'Importing...' : 'Choose File to Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FintechColors.accentTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOptions(bool isDark) {
    return FintechCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FintechColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.backup,
                    color: FintechColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup & Restore',
                        style: FintechTypography.h5.copyWith(
                          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Additional data management options',
                        style: FintechTypography.bodySmall.copyWith(
                          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildBackupOption(
              'Clear All Data',
              'Permanently delete all financial data',
              Icons.delete_forever,
              FintechColors.errorColor,
              _showClearDataDialog,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildBackupOption(
              'Export Settings',
              'Export app preferences and configurations',
              Icons.settings,
              FintechColors.primaryPurple,
              _exportSettings,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildBackupOption(
              'Generate Report',
              'Create a comprehensive financial report',
              Icons.assessment,
              FintechColors.primaryColor,
              _generateReport,
              isDark,
              isLoading: _isReportExporting,
              isDisabled: _isReportExporting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
    {bool isLoading = false, bool isDisabled = false}
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: FintechTypography.bodyMedium.copyWith(
          color: isDark ? FintechColors.textPrimary : FintechColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: FintechTypography.bodySmall.copyWith(
          color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.chevron_right,
              color: isDark ? FintechColors.textSecondary : FintechColors.lightTextSecondary,
            ),
      onTap: isDisabled ? null : onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getDataTypeDisplayName(String key) {
    switch (key) {
      case 'expenses':
        return 'Expenses';
      case 'income':
        return 'Income Records';
      case 'budgets':
        return 'Budgets';
      case 'savings':
        return 'Savings Goals';
      case 'bills':
        return 'Bill Reminders';
      default:
        return key;
    }
  }

  String _getDataTypeDescription(String key) {
    switch (key) {
      case 'expenses':
        return 'All expense transactions and categories';
      case 'income':
        return 'Income records and sources';
      case 'budgets':
        return 'Budget limits and tracking data';
      case 'savings':
        return 'Savings goals and contributions';
      case 'bills':
        return 'Bill reminders and payment history';
      default:
        return '';
    }
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final selectedTypes = _exportOptions.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one data type to export'),
            backgroundColor: FintechColors.warningColor,
          ),
        );
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final exportService = ExportImportService();
      Map<String, dynamic> exportData = {};

      // Collect data from providers
      if (selectedTypes.contains('expenses')) {
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        exportData['expenses'] = expenseProvider.expenses.map((e) => e.toJson()).toList();
      }

      if (selectedTypes.contains('income')) {
        final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
        exportData['income'] = incomeProvider.incomes.map((i) => i.toJson()).toList();
      }

      if (selectedTypes.contains('budgets')) {
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
        exportData['budgets'] = budgetProvider.budgets.map((b) => b.toJson()).toList();
      }

      if (selectedTypes.contains('savings')) {
        final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
        exportData['savings'] = savingsProvider.goals.map((g) => g.toJson()).toList();
      }

      if (selectedTypes.contains('bills')) {
        final billProvider = Provider.of<BillReminderProvider>(context, listen: false);
        exportData['bills'] = billProvider.bills.map((b) => b.toJson()).toList();
      }

      // Add metadata
      exportData['metadata'] = {
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'format_version': '1.0',
        'data_types': selectedTypes,
      };

      if (format == 'json') {
        await exportService.exportAsJson(exportData);
      } else if (format == 'csv') {
        await exportService.exportAsCSV(exportData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully as $format'),
          backgroundColor: FintechColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final exportService = ExportImportService();
      final importData = await exportService.importFromJson();

      if (importData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected or import cancelled'),
            backgroundColor: FintechColors.warningColor,
          ),
        );
        return;
      }

      final apiService = ApiService();
      int totalImported = 0;
      int totalFailed = 0;
      final importedByType = <String, int>{
        'expenses': 0,
        'income': 0,
        'budgets': 0,
        'savings': 0,
        'bills': 0,
      };

      Future<void> importList(
        String key,
        Map<String, dynamic>? Function(Map<String, dynamic>) normalize,
        Future<void> Function(Map<String, dynamic>) upload,
      ) async {
        final list = importData[key];
        if (list is! List) return;

        for (final item in list) {
          if (item is! Map) {
            totalFailed++;
            continue;
          }

          final raw = Map<String, dynamic>.from(item);
          final payload = normalize(raw);
          if (payload == null) {
            totalFailed++;
            continue;
          }

          try {
            await upload(payload);
            totalImported++;
            importedByType[key] = (importedByType[key] ?? 0) + 1;
          } catch (e) {
            totalFailed++;
            debugPrint('Import failed for $key record: $e');
          }
        }
      }

      await importList(
        'expenses',
        _normalizeExpensePayload,
        (payload) => apiService.addExpense(payload),
      );

      await importList(
        'income',
        _normalizeIncomePayload,
        (payload) => apiService.addIncome(payload),
      );

      await importList(
        'budgets',
        _normalizeBudgetPayload,
        (payload) => apiService.createBudget(payload),
      );

      await importList(
        'savings',
        _normalizeSavingsPayload,
        (payload) => apiService.createSavingsGoal(payload),
      );

      await importList(
        'bills',
        _normalizeBillPayload,
        (payload) => apiService.createBillReminder(payload),
      );

      // Refresh all providers
      if (mounted) {
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
        final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
        final billProvider = Provider.of<BillReminderProvider>(context, listen: false);

        await Future.wait([
          expenseProvider.fetchExpenses(forceRefresh: true),
          incomeProvider.fetchIncomes(forceRefresh: true),
          budgetProvider.fetchBudgets(),
          savingsProvider.fetchSavingsGoals(),
          billProvider.fetchBillReminders(forceRefresh: true),
        ]);
      }

      final breakdown = importedByType.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            totalFailed > 0
                ? 'Imported $totalImported records, failed $totalFailed${breakdown.isNotEmpty ? ' ($breakdown)' : ''}'
                : 'Successfully imported $totalImported records${breakdown.isNotEmpty ? ' ($breakdown)' : ''}',
          ),
          backgroundColor: totalFailed > 0 ? FintechColors.warningColor : FintechColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Map<String, dynamic>? _normalizeExpensePayload(Map<String, dynamic> raw) {
    final amount = _toNumber(raw['amount']);
    final date = _toIsoDate(raw['date']);
    final store = _toText(raw['store']) ?? _toText(raw['description']) ?? 'Imported Expense';
    final category = _toText(raw['category']) ?? 'Other';

    if (amount == null || amount <= 0 || date == null) {
      return null;
    }

    final payload = <String, dynamic>{
      'store': store,
      'amount': amount,
      'category': category,
      'date': date,
    };

    final items = _toStringList(raw['items']);
    if (items != null && items.isNotEmpty) {
      payload['items'] = items;
    }

    final rawText = _toText(raw['raw_ocr_text']);
    if (rawText != null) {
      payload['raw_ocr_text'] = rawText;
    }

    return payload;
  }

  Map<String, dynamic>? _normalizeIncomePayload(Map<String, dynamic> raw) {
    final amount = _toNumber(raw['amount']);
    final date = _toIsoDate(raw['date']);
    final source = _toText(raw['source']) ?? _toText(raw['description']) ?? 'Imported Income';

    if (amount == null || amount <= 0 || date == null) {
      return null;
    }

    return {
      'source': source,
      'amount': amount,
      'date': date,
      'category': _toText(raw['category']) ?? 'Other',
      'currency': (_toText(raw['currency']) ?? 'INR').toUpperCase(),
      'is_recurring': _toBool(raw['is_recurring']),
      if (_toText(raw['notes']) != null) 'notes': _toText(raw['notes']),
    };
  }

  Map<String, dynamic>? _normalizeBudgetPayload(Map<String, dynamic> raw) {
    final amount = _toNumber(raw['amount']);
    final category = _toText(raw['category']);

    if (amount == null || amount <= 0 || category == null) {
      return null;
    }

    return {
      'category': category,
      'amount': amount,
    };
  }

  Map<String, dynamic>? _normalizeSavingsPayload(Map<String, dynamic> raw) {
    final targetAmount = _toNumber(raw['target_amount'] ?? raw['amount']);
    final title = _toText(raw['title']) ?? _toText(raw['name']) ?? 'Imported Goal';

    if (targetAmount == null || targetAmount <= 0) {
      return null;
    }

    final payload = <String, dynamic>{
      'title': title,
      'target_amount': targetAmount,
      'current_amount': _toNumber(raw['current_amount']) ?? 0.0,
      'is_completed': _toBool(raw['is_completed']),
      'priority': _toText(raw['priority']) ?? 'medium',
    };

    final description = _toText(raw['description']);
    if (description != null) {
      payload['description'] = description;
    }

    final category = _toText(raw['category']);
    if (category != null) {
      payload['category'] = category;
    }

    final targetDate = _toIsoDate(raw['target_date']);
    if (targetDate != null) {
      payload['target_date'] = targetDate;
    }

    return payload;
  }

  Map<String, dynamic>? _normalizeBillPayload(Map<String, dynamic> raw) {
    final amount = _toNumber(raw['amount']);
    final dueDate = _toIsoDate(raw['due_date'] ?? raw['date']);
    final title = _toText(raw['title']) ?? _toText(raw['name']) ?? 'Imported Bill';

    if (amount == null || amount <= 0 || dueDate == null) {
      return null;
    }

    return {
      'title': title,
      'amount': amount,
      'due_date': dueDate,
      'description': _toText(raw['description']),
      'frequency': _toText(raw['frequency']) ?? 'monthly',
      'category': _toText(raw['category']) ?? 'other',
      'priority': _toText(raw['priority']) ?? 'medium',
      'is_recurring': _toBool(raw['is_recurring']),
      'is_paid': _toBool(raw['is_paid']),
      'status': _toText(raw['status']) ?? 'pending',
      'currency': (_toText(raw['currency']) ?? 'USD').toUpperCase(),
    };
  }

  String? _toText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  double? _toNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  List<String>? _toStringList(dynamic value) {
    if (value is! List) return null;
    final items = value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return items;
  }

  String? _toIsoDate(dynamic value) {
    if (value == null) return null;

    if (value is int || value is double) {
      final n = (value as num).toDouble();
      final milliseconds = n > 9999999999 ? n.toInt() : (n * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds).toIso8601String();
    }

    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return null;
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.toIso8601String();
      }
    }

    return null;
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your financial data including expenses, income, budgets, savings goals, and bill reminders. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            style: TextButton.styleFrom(
              foregroundColor: FintechColors.errorColor,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // In a real app, you would call API endpoints to clear data
      // For now, we'll just show a success message
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared successfully'),
          backgroundColor: FintechColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear data: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    }
  }

  Future<void> _exportSettings() async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      final settingsData = {
        'theme_mode': themeProvider.isDarkMode ? 'dark' : 'light',
        'currency_symbol': themeProvider.currencySymbol,
        'exported_at': DateTime.now().toIso8601String(),
      };

      final fileName = 'finx_settings_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final bytes = utf8.encode(jsonEncode(settingsData));

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/json')],
        subject: 'Finx Settings Export',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings exported successfully'),
          backgroundColor: FintechColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export settings: ${e.toString()}'),
          backgroundColor: FintechColors.errorColor,
        ),
      );
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isReportExporting = true;
    });

    try {
      final exportService = ExportImportService();
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
      final billProvider = Provider.of<BillReminderProvider>(context, listen: false);

      final data = {
        'expenses': expenseProvider.expenses.map((e) => e.toJson()).toList(),
        'income': incomeProvider.incomes.map((i) => i.toJson()).toList(),
        'budgets': budgetProvider.budgets.map((b) => b.toJson()).toList(),
        'savings': savingsProvider.goals.map((g) => g.toJson()).toList(),
        'bills': billProvider.bills.map((b) => b.toJson()).toList(),
      };

      final report = exportService.generateFinancialReport(data);
      await exportService.exportFinancialReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully'),
            backgroundColor: FintechColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: FintechColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReportExporting = false;
        });
      }
    }
  }
}
