import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/ocr_result_model.dart';
import '../models/subscription_model.dart';
import '../models/budget_model.dart';

class ApiService {
  // Auto-detect environment
  // Debug mode → Local backend
  // Release mode → Production backend
  static const String _productionUrl = 'https://finx-ugs5.onrender.com/api';
  
  // Platform-specific local URLs
  static String get _localUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api'; // Web
    } else if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // For emulator: 10.0.2.2 (localhost alias)
      // For physical device: use your PC's local IP
     return 'http://172.20.0.37:5000/api';// Default to emulator
      // If not working, change to: 'http://172.20.0.37:5000/api' for physical device
    } else if (Platform.isIOS) {
      return 'http://localhost:5000/api'; // iOS simulator
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:5000/api'; // Desktop
    }
    return 'http://localhost:5000/api'; // Fallback
  }
  
  static const String _baseUrlPrefKey = 'api_base_url';
  static String _baseUrl = kReleaseMode ? _productionUrl : _localUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Allow manual override, otherwise use auto-detected URL
    final savedUrl = prefs.getString(_baseUrlPrefKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl.trim();
    } else {
      // Auto-detect: Release = Production, Debug = Local
      _baseUrl = kReleaseMode ? _productionUrl : _localUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/*$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, normalized);
    _baseUrl = normalized;
  }
  
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlPrefKey);
    _baseUrl = kReleaseMode ? _productionUrl : _localUrl;
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
  Future<OCRResult> uploadReceipt(XFile imageFile) async {
    try {
      print('🔐 Getting auth token...');
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }
      print('✓ Token obtained');
      
      print('📦 Preparing multipart request to: $baseUrl/upload-receipt');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-receipt'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // Read file as bytes (works on all platforms)
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.name;
      
      request.files.add(http.MultipartFile.fromBytes(
        'receipt',
        bytes,
        filename: filename,
      ));
      print('✓ File added to request: $filename (${bytes.length} bytes)');
      
      print('🌐 Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Connection timeout. The server took too long to respond.');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      print('📥 Response received: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      final data = _handleResponse(response);
      print('✅ Parsing OCR result...');
      return OCRResult.fromJson(data);
    } on SocketException {
      print('❌ SocketException: No internet connection');
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Failed to connect to server. Please try again.');
    } catch (e) {
      print('❌ Exception during upload: $e');
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

  Future<Map<String, dynamic>> updateIncome(String id, Map<String, dynamic> incomeJson) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/incomes/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(incomeJson),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update income: $e');
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
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('❌ JSON decode error: $e');
        print('Raw response: ${response.body}');
        throw Exception('Invalid response format from server');
      }
    } else {
      print('❌ HTTP Error ${response.statusCode}: ${response.body}');
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Request failed with status ${response.statusCode}');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }
}
