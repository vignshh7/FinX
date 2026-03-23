import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get userName => _user?.name ?? 'User';
  String get userEmail => _user?.email ?? '';
  
  // Save user data to SharedPreferences
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      if (kDebugMode) {
        print('User data saved: ${user.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
    }
  }
  
  // Load user data from SharedPreferences
  Future<User?> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final user = User.fromJson(jsonDecode(userData));
        if (kDebugMode) {
          print('User data loaded: ${user.name}');
        }
        return user;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
    return null;
  }
  
  // Clear user data from SharedPreferences
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      if (kDebugMode) {
        print('User data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user data: $e');
      }
    }
  }
  
  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final token = await _apiService.getToken();
      _isAuthenticated = token != null && token.isNotEmpty;
      if (_isAuthenticated) {
        // Load saved user data
        _user = await _loadUserData();
        if (_user == null) {
          // Fallback to placeholder if no saved data
          _user = User(
            id: 0,
            name: 'User',
            email: '',
            token: token!,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking auth status: $e');
      }
      _isAuthenticated = false;
      notifyListeners();
    }
  }
  
  // Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.register(name, email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Registration error: $_error');
      }
      return false;
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _user = await _apiService.login(email, password);
      _isAuthenticated = true;
      
      // Save user data to persistent storage
      await _saveUserData(_user!);
      
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Login successful for user: ${_user?.name} (${_user?.email})');
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Login error: $_error');
      }
      return false;
    }
  }
  
  // Logout - Clear all user data
  Future<void> logout() async {
    await _apiService.deleteToken();
    await _clearUserData();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
    if (kDebugMode) {
      print('User logged out successfully');
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
