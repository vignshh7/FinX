import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/ocr_result_model.dart';
import '../models/subscription_model.dart';
import '../models/budget_model.dart';

class ApiService {
  // Backend base URL (configurable from Settings)
  // Defaults:
  // - Android emulator: http://10.0.2.2:5000/api
  // - Physical device:  http://<your-computer-lan-ip>:5000/api
  static const String _baseUrlPrefKey = 'api_base_url';
  static const String _defaultBaseUrl = 'https://finx-ugs5.onrender.com/api';
  static String _baseUrl = _defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = (prefs.getString(_baseUrlPrefKey) ?? _defaultBaseUrl).trim();
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/*$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, normalized);
    _baseUrl = normalized;
  }
  
  final _storage = const FlutterSecureStorage();
  
  // Token Management
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
  
  // Headers with JWT
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Authentication APIs
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      
      final data = _handleResponse(response);
      final user = User.fromJson(data);
      await saveToken(user.token);
      return user;
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // OCR Upload API
  Future<OCRResult> uploadReceipt(File imageFile) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-receipt'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'receipt',
        imageFile.path,
      ));
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Connection timeout. The server took too long to respond.');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      final data = _handleResponse(response);
      return OCRResult.fromJson(data);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Receipt upload failed: ${e.toString()}');
    }
  }
  
  // Expense APIs
  Future<List<Expense>> getExpenses({String? category, String? startDate, String? endDate}) async {
    try {
      var uri = Uri.parse('$baseUrl/expenses');
      
      Map<String, String> queryParams = {};
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(uri, headers: await _getHeaders());
      final data = _handleResponse(response);
      
      return (data['expenses'] as List)
          .map((e) => Expense.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }
  
  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: await _getHeaders(),
        body: jsonEncode(expense.toJson()),
      );
      
      final data = _handleResponse(response);
      return Expense.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }
  
  Future<void> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: await _getHeaders(),
      );
      
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }
  
  // Prediction API
  Future<Map<String, dynamic>> getSpendingPrediction() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/predict'),
        headers: await _getHeaders(),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get prediction: $e');
    }
  }
  
  // Alerts API
  Future<List<dynamic>> getAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts'),
        headers: await _getHeaders(),
      );
      
      final data = _handleResponse(response);
      return data['alerts'] as List;
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }
  
  // Subscription APIs
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions'),
        headers: await _getHeaders(),
      );
      
      final data = _handleResponse(response);
      return (data['subscriptions'] as List)
          .map((s) => Subscription.fromJson(s))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }
  
  Future<Subscription> createSubscription(Subscription subscription) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions'),
        headers: await _getHeaders(),
        body: jsonEncode(subscription.toJson()),
      );
      
      final data = _handleResponse(response);
      return Subscription.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }
  
  Future<void> deleteSubscription(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/subscriptions/$id'),
        headers: await _getHeaders(),
      );
      
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete subscription: $e');
    }
  }
  
  // Budget APIs
  Future<Budget> getBudget() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budget'),
        headers: await _getHeaders(),
      );
      
      final data = _handleResponse(response);
      return Budget.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch budget: $e');
    }
  }
  
  Future<Budget> updateBudget(double monthlyLimit, String currency) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/budget'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'monthly_limit': monthlyLimit,
          'currency': currency,
        }),
      );
      
      final data = _handleResponse(response);
      return Budget.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryBudgets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budget/categories'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      return (data['category_budgets'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch category budgets: $e');
    }
  }

  Future<List<Map<String, dynamic>>> upsertCategoryBudgets(
      List<Map<String, dynamic>> budgets) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/budget/categories'),
        headers: await _getHeaders(),
        body: jsonEncode({'category_budgets': budgets}),
      );

      final data = _handleResponse(response);
      return (data['category_budgets'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw Exception('Failed to update category budgets: $e');
    }
  }

  // Income APIs
  Future<Map<String, dynamic>> getIncomes({int? month, int? year}) async {
    try {
      var uri = Uri.parse('$baseUrl/incomes');

      final query = <String, String>{};
      if (month != null) query['month'] = month.toString();
      if (year != null) query['year'] = year.toString();
      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }

      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch incomes: $e');
    }
  }

  Future<Map<String, dynamic>> addIncome(Map<String, dynamic> incomeJson) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incomes'),
        headers: await _getHeaders(),
        body: jsonEncode(incomeJson),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/incomes/$id'),
        headers: await _getHeaders(),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    }
  }

  // Dashboard & Insights APIs
  Future<Map<String, dynamic>> getDashboardSummary({String? month, String? year}) async {
    try {
      var uri = Uri.parse('$baseUrl/dashboard');

      final query = <String, String>{};
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;
      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }

      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> getAiInsights({String? month, String? year}) async {
    try {
      var uri = Uri.parse('$baseUrl/ai-insights');

      final query = <String, String>{};
      if (month != null) query['month'] = month;
      if (year != null) query['year'] = year;
      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }

      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch AI insights: $e');
    }
  }

  Future<void> submitCategorizationFeedback({
    required int expenseId,
    required String correctCategory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses/$expenseId/feedback'),
        headers: await _getHeaders(),
        body: jsonEncode({'correct_category': correctCategory}),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Response Handler
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Request failed');
    }
  }
}
