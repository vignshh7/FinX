import 'package:flutter/foundation.dart';
import '../models/income_model.dart';
import '../services/api_service.dart';

class IncomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;
  
  // Cache timestamp for smart API calls
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Check if cache is still valid
  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }
  
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

  Future<void> fetchIncomes({bool forceRefresh = false}) async {
    // Skip if cache is valid and no force refresh
    if (!forceRefresh && _isCacheValid()) {
      if (kDebugMode) {
        print('Using cached incomes data');
      }
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getIncomes();
      _incomes = (response['incomes'] as List)
          .map((json) => Income.fromJson(json))
          .toList();
      _lastFetch = DateTime.now();
      _error = null;
      if (kDebugMode) {
        print('Incomes fetched: ${_incomes.length} items');
      }
    } catch (e) {
      _error = e.toString();
      _incomes = [];
      if (kDebugMode) {
        print('Error fetching incomes: $_error');
      }
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
      _lastFetch = null; // Invalidate cache
      notifyListeners();
      if (kDebugMode) {
        print('Income added successfully, cache invalidated');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final response = await _apiService.updateIncome(income.id, income.toJson());
      final updatedIncome = Income.fromJson(response);
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = updatedIncome;
        _lastFetch = null; // Invalidate cache
        notifyListeners();
        if (kDebugMode) {
          print('Income updated successfully, cache invalidated');
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _apiService.deleteIncome(id);
      _incomes.removeWhere((income) => income.id == id);
      _lastFetch = null; // Invalidate cache
      notifyListeners();
      if (kDebugMode) {
        print('Income deleted successfully, cache invalidated');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  // Clear all cached data (call on logout)
  void clearCache() {
    _incomes = [];
    _lastFetch = null;
    _error = null;
    notifyListeners();
    if (kDebugMode) {
      print('IncomeProvider cache cleared');
    }
  }
}
