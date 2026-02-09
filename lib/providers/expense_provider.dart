import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/ocr_result_model.dart';
import '../services/api_service.dart';
import 'dart:io';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  OCRResult? _lastOcrResult;
  Map<String, dynamic>? _prediction;
  List<dynamic> _alerts = [];
  
  // Cache timestamps for smart API calls
  DateTime? _lastExpensesFetch;
  DateTime? _lastPredictionFetch;
  DateTime? _lastAlertsFetch;
  
  // Cache duration (5 minutes for mobile optimization)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OCRResult? get lastOcrResult => _lastOcrResult;
  Map<String, dynamic>? get prediction => _prediction;
  List<dynamic> get alerts => _alerts;
  
  // Calculate total expenses
  double get total {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  // Check if cache is still valid
  bool _isCacheValid(DateTime? lastFetch) {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheDuration;
  }
  
  // Fetch expenses with caching
  Future<void> fetchExpenses({
    String? category, 
    String? startDate, 
    String? endDate,
    bool forceRefresh = false,
  }) async {
    // Skip if cache is valid and no force refresh
    if (!forceRefresh && _isCacheValid(_lastExpensesFetch)) {
      if (kDebugMode) {
        print('Using cached expenses data');
      }
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _expenses = await _apiService.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _lastExpensesFetch = DateTime.now();
      _error = null;
      if (kDebugMode) {
        print('Expenses fetched: ${_expenses.length} items');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching expenses: $_error');
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Upload receipt for OCR
  Future<OCRResult?> uploadReceipt(File imageFile) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _lastOcrResult = await _apiService.uploadReceipt(imageFile);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return _lastOcrResult;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Add expense - invalidate cache
  Future<bool> addExpense(Expense expense) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newExpense = await _apiService.createExpense(expense);
      _expenses.insert(0, newExpense);
      
      // Invalidate cache to force refresh on next fetch
      _lastExpensesFetch = null;
      _lastPredictionFetch = null;
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Expense added successfully, cache invalidated');
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete expense - invalidate cache
  Future<bool> deleteExpense(int id) async {
    try {
      await _apiService.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
      
      // Invalidate cache to force refresh on next fetch
      _lastExpensesFetch = null;
      _lastPredictionFetch = null;
      
      notifyListeners();
      if (kDebugMode) {
        print('Expense deleted successfully, cache invalidated');
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get spending prediction with caching
  Future<void> fetchPrediction({bool forceRefresh = false}) async {
    // Skip if cache is valid and no force refresh
    if (!forceRefresh && _isCacheValid(_lastPredictionFetch)) {
      if (kDebugMode) {
        print('Using cached prediction data');
      }
      return;
    }
    
    try {
      _prediction = await _apiService.getSpendingPrediction();
      _lastPredictionFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('Prediction fetched successfully');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching prediction: $_error');
      }
    }
  }
  
  // Get alerts with caching
  Future<void> fetchAlerts({bool forceRefresh = false}) async {
    // Skip if cache is valid and no force refresh
    if (!forceRefresh && _isCacheValid(_lastAlertsFetch)) {
      if (kDebugMode) {
        print('Using cached alerts data');
      }
      return;
    }
    
    try {
      _alerts = await _apiService.getAlerts();
      _lastAlertsFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('Alerts fetched: ${_alerts.length} items');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching alerts: $_error');
      }
    }
  }
  
  // Calculate monthly total
  double get monthlyTotal {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _expenses
        .where((e) => e.date.isAfter(firstDayOfMonth) && e.date.isBefore(lastDayOfMonth))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  // Calculate category totals
  Map<String, double> get categoryTotals {
    Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearOcrResult() {
    _lastOcrResult = null;
    notifyListeners();
  }
  
  // Clear all cached data (call on logout)
  void clearCache() {
    _expenses = [];
    _prediction = null;
    _alerts = [];
    _lastExpensesFetch = null;
    _lastPredictionFetch = null;
    _lastAlertsFetch = null;
    _lastOcrResult = null;
    _error = null;
    notifyListeners();
    if (kDebugMode) {
      print('ExpenseProvider cache cleared');
    }
  }
}
