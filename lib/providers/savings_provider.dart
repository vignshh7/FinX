import 'package:flutter/foundation.dart';
import '../models/savings_goal_model.dart';
import '../services/api_service.dart';

class SavingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _monthlyReport;

  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;

  List<SavingsGoal> get activeGoals => _goals.where((goal) => !goal.isCompleted).toList();
  List<SavingsGoal> get completedGoals => _goals.where((goal) => goal.isCompleted).toList();

  double get totalTargetAmount {
    return _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  double get totalSavedAmount {
    return _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  /// Sum of all contributions made in the current calendar month
  double get monthlyContributedAmount {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    double total = 0.0;
    for (final goal in _goals) {
      for (final c in goal.contributions) {
        if (!c.date.isBefore(monthStart) && c.date.isBefore(monthEnd)) {
          total += c.amount;
        }
      }
    }
    // Also fall back to monthlyReport if contributions list is empty
    if (total == 0.0 && _monthlyReport != null) {
      total = (_monthlyReport!['total_contributed'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  double get overallProgress {
    return totalTargetAmount > 0 ? totalSavedAmount / totalTargetAmount : 0.0;
  }

  Future<void> fetchSavingsGoals() async {
    _setLoading(true);
    try {
      final goalsData = await _apiService.getSavingsGoals();
      _goals = goalsData.map((data) => SavingsGoal.fromJson(data)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error fetching savings goals: $e');
      
      // Fallback to sample data for development
      _goals = _getSampleGoals();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSavingsGoal(SavingsGoal goal) async {
    try {
      final result = await _apiService.createSavingsGoal(goal.toJson());
      if (result['success'] == true) {
        _goals.add(SavingsGoal.fromJson(result['goal']));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error adding savings goal: $e');
      
      // Fallback for development
      final newGoal = goal.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _goals.add(newGoal);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateSavingsGoal(SavingsGoal goal) async {
    try {
      final result = await _apiService.updateSavingsGoal(goal.id!, goal.toJson());
      if (result['success'] == true) {
        final index = _goals.indexWhere((g) => g.id == goal.id);
        if (index != -1) {
          _goals[index] = SavingsGoal.fromJson(result['goal']);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error updating savings goal: $e');
      
      // Fallback for development
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<bool> deleteSavingsGoal(String goalId) async {
    try {
      final result = await _apiService.deleteSavingsGoal(goalId);
      if (result['success'] == true) {
        _goals.removeWhere((goal) => goal.id == goalId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error deleting savings goal: $e');
      return false;
    }
  }

  Future<bool> addContribution(SavingsContribution contribution) async {
    try {
      final result = await _apiService.addSavingsContribution(contribution.toJson());
      if (result['success'] == true) {
        final updatedGoalData = result['goal'];
        if (updatedGoalData != null) {
          final updatedGoal = SavingsGoal.fromJson(updatedGoalData);
          final goalIndex = _goals.indexWhere((g) => g.id == updatedGoal.id);
          if (goalIndex != -1) {
            _goals[goalIndex] = updatedGoal;
          }
        }

        if (result['monthly_report'] != null) {
          _monthlyReport = result['monthly_report'] as Map<String, dynamic>;
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error adding contribution: $e');
      
      // Fallback for development
      final goalIndex = _goals.indexWhere((g) => g.id == contribution.goalId);
      if (goalIndex != -1) {
        final goal = _goals[goalIndex];
        final newContribution = contribution.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + contribution.amount,
          contributions: [...goal.contributions, newContribution],
          isCompleted: (goal.currentAmount + contribution.amount) >= goal.targetAmount,
        );
        _goals[goalIndex] = updatedGoal;
        _monthlyReport = _buildMonthlyReportFromGoals(DateTime.now());
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<void> fetchMonthlyReport({int? year, int? month}) async {
    try {
      final now = DateTime.now();
      final report = await _apiService.getSavingsMonthlyReport(
        year: year ?? now.year,
        month: month ?? now.month,
      );
      _monthlyReport = report;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _monthlyReport = _buildMonthlyReportFromGoals(DateTime.now());
      notifyListeners();
    }
  }

  Map<String, dynamic> _buildMonthlyReportFromGoals(DateTime date) {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 1);

    double totalContributed = 0.0;
    double totalRemaining = 0.0;
    final goalsSummary = <Map<String, dynamic>>[];

    for (final goal in _goals) {
      final contributed = goal.contributions.where((c) {
        return !c.date.isBefore(monthStart) && c.date.isBefore(monthEnd);
      }).fold<double>(0.0, (sum, c) => sum + c.amount);

      final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
      totalContributed += contributed;
      totalRemaining += remaining;

      goalsSummary.add({
        'goal_id': goal.id,
        'title': goal.title,
        'contributed': contributed,
        'remaining': remaining,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'is_completed': goal.isCompleted,
      });
    }

    return {
      'year': date.year,
      'month': date.month,
      'total_contributed': totalContributed,
      'total_remaining': totalRemaining,
      'goals': goalsSummary,
    };
  }

  SavingsGoal? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  List<SavingsGoal> getGoalsByCategory(SavingsGoalCategory category) {
    return _goals.where((goal) => goal.category == category).toList();
  }

  List<SavingsGoal> getGoalsByStatus(SavingsGoalStatus status) {
    return _goals.where((goal) => goal.status == status).toList();
  }

  List<SavingsGoal> getGoalsByPriority(SavingsGoalPriority priority) {
    return _goals.where((goal) => goal.priority == priority).toList();
  }

  List<SavingsGoal> getUrgentGoals() {
    return _goals.where((goal) => 
      goal.daysRemaining < 30 && !goal.isCompleted
    ).toList();
  }

  List<SavingsGoal> getOverdueGoals() {
    return _goals.where((goal) => goal.isOverdue).toList();
  }

  Map<SavingsGoalCategory, double> getSavingsByCategory() {
    final Map<SavingsGoalCategory, double> categoryTotals = {};
    
    for (final goal in _goals) {
      categoryTotals[goal.category] = 
          (categoryTotals[goal.category] ?? 0.0) + goal.currentAmount;
    }
    
    return categoryTotals;
  }

  List<String> getSavingsInsights() {
    final List<String> insights = [];
    
    // Overall progress insights
    final overallProgressPercentage = overallProgress * 100;
    if (overallProgressPercentage >= 80) {
      insights.add('Excellent progress! You\'re ${overallProgressPercentage.toInt()}% towards your total savings goals.');
    } else if (overallProgressPercentage >= 50) {
      insights.add('Good progress on your savings goals. Keep up the momentum!');
    } else if (overallProgressPercentage < 20 && _goals.isNotEmpty) {
      insights.add('Consider increasing your monthly contributions to stay on track.');
    }
    
    // Completion insights
    final completedCount = completedGoals.length;
    if (completedCount > 0) {
      insights.add('Congratulations! You\'ve completed $completedCount savings ${completedCount == 1 ? 'goal' : 'goals'}.');
    }
    
    // Urgent goals
    final urgentGoals = getUrgentGoals();
    if (urgentGoals.isNotEmpty) {
      insights.add('${urgentGoals.length} of your goals need attention - less than 30 days remaining.');
    }
    
    // Overdue goals
    final overdueGoals = getOverdueGoals();
    if (overdueGoals.isNotEmpty) {
      insights.add('You have ${overdueGoals.length} overdue ${overdueGoals.length == 1 ? 'goal' : 'goals'}. Consider extending the deadline or adjusting the target.');
    }
    
    // Category insights
    final categoryTotals = getSavingsByCategory();
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Your highest savings category is ${topCategory.key.displayName}.');
    }
    
    // Goal recommendations
    if (_goals.isEmpty) {
      insights.add('Start your savings journey by creating your first goal!');
    } else if (_goals.length < 3) {
      insights.add('Consider diversifying your savings with goals in different categories.');
    }
    
    return insights;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sample data for development
  List<SavingsGoal> _getSampleGoals() {
    return [
      SavingsGoal(
        id: '1',
        title: 'Emergency Fund',
        description: 'Build a 6-month emergency fund for financial security',
        targetAmount: 15000.0,
        currentAmount: 8500.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        category: SavingsGoalCategory.emergency,
        priority: SavingsGoalPriority.high,
        contributions: [
          SavingsContribution(
            id: 'c1',
            goalId: '1',
            amount: 1000.0,
            date: DateTime.now().subtract(const Duration(days: 30)),
            note: 'Monthly contribution',
          ),
          SavingsContribution(
            id: 'c2',
            goalId: '1',
            amount: 1500.0,
            date: DateTime.now().subtract(const Duration(days: 60)),
            note: 'Bonus deposit',
          ),
        ],
      ),
      SavingsGoal(
        id: '2',
        title: 'Dream Vacation',
        description: 'Trip to Japan for 2 weeks',
        targetAmount: 5000.0,
        currentAmount: 2200.0,
        targetDate: DateTime.now().add(const Duration(days: 300)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        category: SavingsGoalCategory.vacation,
        priority: SavingsGoalPriority.medium,
        contributions: [
          SavingsContribution(
            id: 'c3',
            goalId: '2',
            amount: 500.0,
            date: DateTime.now().subtract(const Duration(days: 15)),
            note: 'Weekly savings',
          ),
        ],
      ),
      SavingsGoal(
        id: '3',
        title: 'New Laptop',
        description: 'MacBook Pro for work',
        targetAmount: 2500.0,
        currentAmount: 2500.0,
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        category: SavingsGoalCategory.electronics,
        priority: SavingsGoalPriority.medium,
        isCompleted: true,
        contributions: [
          SavingsContribution(
            id: 'c4',
            goalId: '3',
            amount: 2500.0,
            date: DateTime.now().subtract(const Duration(days: 10)),
            note: 'Final payment',
          ),
        ],
      ),
    ];
  }
}