import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense_model.dart';
import '../models/ocr_result_model.dart';
import '../services/api_service.dart';

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
  String? _lastCategoryParam;
  String? _lastStartDateParam;
  String? _lastEndDateParam;
  
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
    final paramsChanged = category != _lastCategoryParam ||
        startDate != _lastStartDateParam ||
        endDate != _lastEndDateParam;
    final shouldForceRefresh = forceRefresh || paramsChanged;

    // Skip if cache is valid and no force refresh
    if (!shouldForceRefresh && _isCacheValid(_lastExpensesFetch)) {
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
      _lastCategoryParam = category;
      _lastStartDateParam = startDate;
      _lastEndDateParam = endDate;
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
  Future<OCRResult?> uploadReceipt(XFile imageFile) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('📤 Uploading receipt: ${imageFile.path}');
      _lastOcrResult = await _apiService.uploadReceipt(imageFile);
      print('✅ OCR Result received: ${_lastOcrResult?.store}, ${_lastOcrResult?.amount}');
      _error = null;
      _isLoading = false;
      notifyListeners();
      return _lastOcrResult;
    } catch (e) {
      print('❌ Upload receipt error: $e');
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
        .where((e) => e.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) && 
               e.date.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Calculate past month total
  double get pastMonthTotal {
    final now = DateTime.now();
    final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    
    return _expenses
        .where((e) => e.date.isAfter(firstDayOfLastMonth.subtract(const Duration(days: 1))) && 
               e.date.isBefore(lastDayOfLastMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  // Get expenses for a specific month
  List<Expense> getExpensesForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    return _expenses
        .where((e) => e.date.isAfter(firstDay.subtract(const Duration(days: 1))) && 
               e.date.isBefore(lastDay.add(const Duration(days: 1))))
        .toList();
  }
  
  // Get expenses for past month
  List<Expense> get pastMonthExpenses {
    final now = DateTime.now();
    final pastMonth = DateTime(now.year, now.month - 1, 1);
    return getExpensesForMonth(pastMonth);
  }
  
  // Get current month expenses
  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    return getExpensesForMonth(currentMonth);
  }
  
  // Get expenses for date range
  List<Expense> getExpensesForDateRange(DateTime startDate, DateTime endDate) {
    return _expenses
        .where((e) => e.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
               e.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
  
  // Calculate category totals
  Map<String, double> get categoryTotals {
    return getCategoryTotalsForPeriod();
  }
  
  // Calculate category totals for current month
  Map<String, double> get currentMonthCategoryTotals {
    return getCategoryTotalsForPeriod(currentMonthExpenses);
  }
  
  // Calculate category totals for past month
  Map<String, double> get pastMonthCategoryTotals {
    return getCategoryTotalsForPeriod(pastMonthExpenses);
  }
  
  // Helper method to get category totals for a specific expense list
  Map<String, double> getCategoryTotalsForPeriod([List<Expense>? expenseList]) {
    final expenses = expenseList ?? _expenses;
    Map<String, double> totals = {};
    for (var expense in expenses) {
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

  // =================================
  // COMPREHENSIVE AI FUNCTIONALITY
  // =================================

  // Store AI analysis data
  Map<String, dynamic>? _completeAIAnalysis;
  Map<String, dynamic>? _financialAdvice;
  Map<String, dynamic>? _spendingAggregation;
  Map<String, dynamic>? _aiInsights;

  // Cache timestamps for new AI features
  DateTime? _lastCompleteAnalysisFetch;
  DateTime? _lastAdviceFetch;
  DateTime? _lastAggregationFetch;
  DateTime? _lastInsightsFetch;

  // Getters for AI data
  Map<String, dynamic>? get completeAIAnalysis => _completeAIAnalysis;
  Map<String, dynamic>? get financialAdvice => _financialAdvice;
  Map<String, dynamic>? get spendingAggregation => _spendingAggregation;
  Map<String, dynamic>? get aiInsights => _aiInsights;

  // Get complete AI analysis
  Future<void> fetchCompleteAIAnalysis({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastCompleteAnalysisFetch)) {
      if (kDebugMode) {
        print('Using cached complete AI analysis');
      }
      return;
    }

    try {
      _completeAIAnalysis = await _apiService.getCompleteAIAnalysis();
      _lastCompleteAnalysisFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('Complete AI analysis fetched successfully');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching complete AI analysis: $_error');
      }
    }
  }

  // Get financial advice
  Future<void> fetchFinancialAdvice({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastAdviceFetch)) {
      if (kDebugMode) {
        print('Using cached financial advice');
      }
      return;
    }

    try {
      _financialAdvice = await _apiService.getFinancialAdvice();
      _lastAdviceFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('Financial advice fetched successfully');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching financial advice: $_error');
      }
    }
  }

  // Get spending aggregation
  Future<void> fetchSpendingAggregation({int months = 6, bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastAggregationFetch)) {
      if (kDebugMode) {
        print('Using cached spending aggregation');
      }
      return;
    }

    try {
      _spendingAggregation = await _apiService.getSpendingAggregation(months: months);
      _lastAggregationFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('Spending aggregation fetched successfully');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching spending aggregation: $_error');
      }
    }
  }

  // Enhanced AI insights (using the new endpoint)
  Future<void> fetchAIInsights({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastInsightsFetch)) {
      if (kDebugMode) {
        print('Using cached AI insights');
      }
      return;
    }

    try {
      _aiInsights = await _apiService.getAiInsights();
      _lastInsightsFetch = DateTime.now();
      notifyListeners();
      if (kDebugMode) {
        print('AI insights fetched successfully');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching AI insights: $_error');
      }
    }
  }

  // Auto-categorize expenses when adding
  Future<Map<String, dynamic>?> categorizeExpense({
    required String storeName,
    List<String>? items,
    String? description,
  }) async {
    try {
      final result = await _apiService.categorizeExpense(
        storeName: storeName,
        items: items,
        description: description,
      );
      if (kDebugMode) {
        print('Expense categorized: ${result['category']} (${result['confidence']})');
      }
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error categorizing expense: $_error');
      }
      return null;
    }
  }

  // Load all AI data at once  
  Future<void> loadAllAIData({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchCompleteAIAnalysis(forceRefresh: forceRefresh),
        fetchFinancialAdvice(forceRefresh: forceRefresh),
        fetchSpendingAggregation(forceRefresh: forceRefresh),
        fetchAIInsights(forceRefresh: forceRefresh),
        fetchPrediction(forceRefresh: forceRefresh),
        fetchAlerts(forceRefresh: forceRefresh),
      ]);
      
      if (kDebugMode) {
        print('All AI data loaded successfully');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading AI data: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to calculate category totals for budgets
  double getCategoryTotal(String category) {
    if (_expenses.isEmpty) return 0.0;
    
    return currentMonthExpenses
        .where((expense) => expense.category.toLowerCase() == category.toLowerCase())
        .fold(0.0, (total, expense) => total + expense.amount);
  }
  
  // Get category total for past month
  double getPastMonthCategoryTotal(String category) {
    if (_expenses.isEmpty) return 0.0;
    
    return pastMonthExpenses
        .where((expense) => expense.category.toLowerCase() == category.toLowerCase())
        .fold(0.0, (total, expense) => total + expense.amount);
  }
  
  // Get category total for date range
  double getCategoryTotalForDateRange(String category, DateTime startDate, DateTime endDate) {
    if (_expenses.isEmpty) return 0.0;
    
    return getExpensesForDateRange(startDate, endDate)
        .where((expense) => expense.category.toLowerCase() == category.toLowerCase())
        .fold(0.0, (total, expense) => total + expense.amount);
  }
  
  // Get spending insights comparing current and past month
  Map<String, dynamic> getSpendingComparison() {
    final currentMonthTotal = monthlyTotal;
    final pastMonthTotal = this.pastMonthTotal;
    final difference = currentMonthTotal - pastMonthTotal;
    final percentageChange = pastMonthTotal > 0 ? (difference / pastMonthTotal) * 100 : 0.0;
    
    return {
      'currentMonth': currentMonthTotal,
      'pastMonth': pastMonthTotal,
      'difference': difference,
      'percentageChange': percentageChange,
      'isIncreasing': difference > 0,
      'categoryComparison': _getCategoryComparison(),
    };
  }
  
  Map<String, Map<String, double>> _getCategoryComparison() {
    final currentTotals = currentMonthCategoryTotals;
    final pastTotals = pastMonthCategoryTotals;
    final comparison = <String, Map<String, double>>{};
    
    final allCategories = {...currentTotals.keys, ...pastTotals.keys};
    
    for (final category in allCategories) {
      final current = currentTotals[category] ?? 0.0;
      final past = pastTotals[category] ?? 0.0;
      final difference = current - past;
      final percentageChange = past > 0 ? (difference / past) * 100 : 0.0;
      
      comparison[category] = {
        'current': current,
        'past': past,
        'difference': difference,
        'percentageChange': percentageChange,
      };
    }
    
    return comparison;
  }
}
