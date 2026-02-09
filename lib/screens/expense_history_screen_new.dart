import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/fintech_colors.dart';
import '../core/theme/fintech_typography.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'store'
  bool _sortAscending = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    await expenseProvider.fetchExpenses(
      category: _selectedCategory,
      startDate: _startDate?.toIso8601String(),
      endDate: _endDate?.toIso8601String(),
    );
  }

  List<Expense> _filterAndSortExpenses(List<Expense> expenses) {
    // Apply search filter
    var filtered = expenses;
    if (_searchQuery.isNotEmpty) {
      filtered = expenses.where((expense) {
        return expense.store.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'store':
          comparison = a.store.compareTo(b.store);
          break;
        case 'date':
        default:
          comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _deleteExpense(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
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

    if (confirmed == true) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final success = await expenseProvider.deleteExpense(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Expense deleted' : 'Failed to delete'),
            backgroundColor: success ? FintechColors.successColor : FintechColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showDateRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadExpenses();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadExpenses();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sort by Date'),
                leading: Radio<String>(
                  value: 'date',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Sort by Amount'),
                leading: Radio<String>(
                  value: 'amount',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Sort by Store'),
                leading: Radio<String>(
                  value: 'store',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(_sortAscending ? 'Ascending' : 'Descending'),
                leading: const Icon(Icons.swap_vert),
                onTap: () {
                  setState(() => _sortAscending = !_sortAscending);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencySymbol = themeProvider.currencySymbol;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    final filteredExpenses = _filterAndSortExpenses(expenseProvider.expenses);
    final totalAmount = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: isDark ? FintechColors.darkBackground : FintechColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Expense History',
          style: FintechTypography.h5.copyWith(
            color: isDark ? FintechColors.darkText : FintechColors.lightText,
          ),
        ),
        backgroundColor: isDark ? FintechColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: isDark ? FintechColors.darkText : FintechColors.lightText,
            ),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? FintechColors.darkText : FintechColors.lightText,
            ),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        color: FintechColors.primaryColor,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              color: isDark ? FintechColors.darkSurface : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: Icon(Icons.search, color: FintechColors.textSecondary),
                      filled: true,
                      fillColor: isDark 
                          ? FintechColors.darkBackground 
                          : FintechColors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Date Range Filter
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDateRangeFilter,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
                                : 'Date Range',
                            style: FintechTypography.bodySmall,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FintechColors.primaryColor,
                            side: BorderSide(
                              color: _startDate != null 
                                  ? FintechColors.primaryColor 
                                  : FintechColors.borderColor,
                            ),
                          ),
                        ),
                      ),
                      if (_startDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearDateFilter,
                          color: FintechColors.errorColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Category Filter
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildCategoryChip('All', null, isDark),
                  ...ExpenseCategory.all.map((category) => 
                    _buildCategoryChip(category, category, isDark)
                  ),
                ],
              ),
            ),

            // Total Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: FintechColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: FintechColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: FintechTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currencySymbol${totalAmount.toStringAsFixed(2)}',
                        style: FintechTypography.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredExpenses.length} items',
                      style: FintechTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expense List
            Expanded(
              child: expenseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 80,
                                color: FintechColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses found',
                                style: FintechTypography.h6.copyWith(
                                  color: FintechColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategory != null
                                    ? 'Try adjusting your filters'
                                    : 'Start tracking your expenses',
                                style: FintechTypography.bodySmall.copyWith(
                                  color: FintechColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 80),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return _buildExpenseCard(expense, currencySymbol, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category, bool isDark) {
    final isSelected = _selectedCategory == category;
    final color = category != null ? ExpenseCategory.getColor(category) : FintechColors.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _loadExpenses();
        },
        avatar: category != null
            ? Icon(
                ExpenseCategory.getIcon(category),
                size: 18,
                color: isSelected ? Colors.white : color,
              )
            : null,
        selectedColor: color,
        backgroundColor: isDark ? FintechColors.darkSurface : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? FintechColors.darkText : FintechColors.lightText),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, String currencySymbol, bool isDark) {
    final categoryColor = ExpenseCategory.getColor(expense.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? FintechColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            ExpenseCategory.getIcon(expense.category),
            color: categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          expense.store,
          style: FintechTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? FintechColors.darkText : FintechColors.lightText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    expense.category,
                    style: FintechTypography.caption.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 12, color: FintechColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(expense.date),
                  style: FintechTypography.caption.copyWith(
                    color: FintechColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (expense.items != null && expense.items!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expense.items!.take(3).join(', '),
                style: FintechTypography.caption.copyWith(
                  color: FintechColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currencySymbol${expense.amount.toStringAsFixed(2)}',
              style: FintechTypography.h6.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? FintechColors.darkText : FintechColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: FintechColors.errorColor,
              onPressed: () => _deleteExpense(expense.id!),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
