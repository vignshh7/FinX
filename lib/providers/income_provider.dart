import 'package:flutter/foundation.dart';
import '../models/income_model.dart';
import '../services/api_service.dart';

class IncomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Calculate total income
  double get total {
    return _incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double get monthlyTotal {
    final now = DateTime.now();
    return _incomes
        .where((income) =>
            income.date.month == now.month && income.date.year == now.year)
        .fold<double>(0, (sum, income) => sum + income.amount);
  }

  double get yearlyTotal {
    final now = DateTime.now();
    return _incomes
        .where((income) => income.date.year == now.year)
        .fold<double>(0, (sum, income) => sum + income.amount);
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (var income in _incomes) {
      totals[income.category] = (totals[income.category] ?? 0) + income.amount;
    }
    return totals;
  }

  Future<void> fetchIncomes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getIncomes();
      _incomes = (response['incomes'] as List)
          .map((json) => Income.fromJson(json))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _incomes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIncome(Income income) async {
    try {
      final response = await _apiService.addIncome(income.toJson());
      final newIncome = Income.fromJson(response);
      _incomes.insert(0, newIncome);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _apiService.deleteIncome(id);
      _incomes.removeWhere((income) => income.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
