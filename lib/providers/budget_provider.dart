import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../services/api_service.dart';
import '../providers/expense_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBudget {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }

  Future<void> fetchBudgets() async {
    _setLoading(true);
    try {
      final budgetData = await _apiService.getBudgets();
      _budgets = budgetData.map((data) => Budget.fromJson(data)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error fetching budgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addBudget(Budget budget) async {
    try {
      final result = await _apiService.createBudget(budget.toJson());
      if (result['success'] == true) {
        _budgets.add(Budget.fromJson(result['budget']));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error adding budget: $e');
      return false;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      final result = await _apiService.updateBudget(budget.id!, budget.toJson());
      if (result['success'] == true) {
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          _budgets[index] = Budget.fromJson(result['budget']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error updating budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    try {
      final result = await _apiService.deleteBudget(budgetId);
      if (result['success'] == true) {
        _budgets.removeWhere((budget) => budget.id == budgetId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error deleting budget: $e');
      return false;
    }
  }

  Budget? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  double getBudgetUsagePercentage(String category, double spent) {
    final budget = getBudgetForCategory(category);
    if (budget == null || budget.amount == 0) return 0.0;
    return spent / budget.amount;
  }

  Map<String, double> getBudgetStatus(ExpenseProvider expenseProvider) {
    final Map<String, double> status = {};
    
    for (final budget in _budgets) {
      final spent = expenseProvider.getCategoryTotal(budget.category);
      final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
      status[budget.category] = percentage;
    }
    
    return status;
  }

  List<String> getBudgetInsights(ExpenseProvider expenseProvider) {
    final List<String> insights = [];
    final budgetStatus = getBudgetStatus(expenseProvider);
    
    // Check for overspending
    final overBudget = budgetStatus.entries
        .where((entry) => entry.value > 1.0)
        .toList();
    
    if (overBudget.isNotEmpty) {
      insights.add('You\'ve exceeded your budget in ${overBudget.length} ${overBudget.length == 1 ? 'category' : 'categories'}.');
    }
    
    // Check for categories approaching limit
    final approaching = budgetStatus.entries
        .where((entry) => entry.value > 0.8 && entry.value <= 1.0)
        .toList();
    
    if (approaching.isNotEmpty) {
      insights.add('You\'re approaching your budget limit in ${approaching.first.key}.');
    }
    
    // Check for well-managed budgets
    final wellManaged = budgetStatus.entries
        .where((entry) => entry.value >= 0.5 && entry.value <= 0.8)
        .toList();
    
    if (wellManaged.isNotEmpty) {
      insights.add('Great job managing your ${wellManaged.first.key} budget!');
    }
    
    // Check for unused budgets
    final unused = budgetStatus.entries
        .where((entry) => entry.value < 0.1)
        .toList();
    
    if (unused.isNotEmpty && unused.length > 1) {
      insights.add('You have ${unused.length} categories with minimal spending this month.');
    }
    
    // Overall budget performance
    final totalBudgeted = totalBudget;
    final totalSpent = expenseProvider.monthlyTotal;
    
    if (totalBudgeted > 0) {
      final overallPercentage = totalSpent / totalBudgeted;
      
      if (overallPercentage < 0.7) {
        insights.add('You\'re doing excellent with your overall budget control!');
      } else if (overallPercentage > 1.1) {
        insights.add('Consider reviewing your spending habits to stay within budget.');
      }
    }
    
    // Budget recommendations
    if (_budgets.length < 3) {
      insights.add('Consider setting budgets for more categories to better track your spending.');
    }
    
    return insights;
  }

  List<Budget> getExceedingBudgets(ExpenseProvider expenseProvider) {
    return _budgets.where((budget) {
      final spent = expenseProvider.getCategoryTotal(budget.category);
      return spent > budget.amount;
    }).toList();
  }

  List<Budget> getApproachingBudgets(ExpenseProvider expenseProvider, {double threshold = 0.8}) {
    return _budgets.where((budget) {
      final spent = expenseProvider.getCategoryTotal(budget.category);
      final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
      return percentage >= threshold && percentage <= 1.0;
    }).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}