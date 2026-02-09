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
  
  // Fetch expenses
  Future<void> fetchExpenses({String? category, String? startDate, String? endDate}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _expenses = await _apiService.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
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
  
  // Add expense
  Future<bool> addExpense(Expense expense) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newExpense = await _apiService.createExpense(expense);
      _expenses.insert(0, newExpense);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete expense
  Future<bool> deleteExpense(int id) async {
    try {
      await _apiService.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get spending prediction
  Future<void> fetchPrediction() async {
    try {
      _prediction = await _apiService.getSpendingPrediction();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Get alerts
  Future<void> fetchAlerts() async {
    try {
      _alerts = await _apiService.getAlerts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
}
