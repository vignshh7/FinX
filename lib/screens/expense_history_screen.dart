import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
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
    await expenseProvider.fetchExpenses(category: _selectedCategory);
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    if (_searchQuery.isEmpty) return expenses;
    
    return expenses.where((expense) {
      return expense.store.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            backgroundColor: success ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: themeProvider.currency);
    
    final filteredExpenses = _filterExpenses(expenseProvider.expenses);

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Expense History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: SafeArea(
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
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by store name...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                      ),

                      // Category Filter
                      SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildCategoryChip('All', null),
                            ...ExpenseCategory.all.map((category) => _buildCategoryChip(category, category)),
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
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No expenses found',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadExpenses,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(16),
                                      itemCount: filteredExpenses.length,
                                      itemBuilder: (context, index) {
                                        final expense = filteredExpenses[index];
                                        return _buildExpenseCard(expense, currencyFormat);
                                      },
                                    ),
                                  ),
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
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    
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
                color: isSelected ? Colors.white : ExpenseCategory.getColor(category),
              )
            : null,
        selectedColor: category != null ? ExpenseCategory.getColor(category) : Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, NumberFormat format) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ExpenseCategory.getColor(expense.category),
          child: Icon(
            ExpenseCategory.getIcon(expense.category),
            color: cs.onPrimary,
          ),
        ),
        title: Text(
          expense.store,
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.category, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
            Text(
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
            ),
            if (expense.items != null && expense.items!.isNotEmpty)
              Text(
                expense.items!.take(2).join(', '),
                style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              format.format(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: cs.error,
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
