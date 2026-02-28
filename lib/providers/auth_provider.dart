import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // TEMPORARY: Hardcoded credentials for development
  static const String _tempUsername = 'admin';
  static const String _tempPassword = 'admin';
  static const bool _useTempAuth = false; // Set to true to bypass backend auth (not recommended)
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  
  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    if (_useTempAuth) {
      // For temporary auth, always consider authenticated
      _isAuthenticated = true;
      _user = User(
        id: 1,
        name: 'Admin User',
        email: 'admin@finx.app',
        token: 'temp_admin_token',
      );
      notifyListeners();
      return;
    }
    
    final token = await _apiService.getToken();
    _isAuthenticated = token != null && token.isNotEmpty;
    if (_isAuthenticated) {
      // We don't currently fetch profile on app start; keep a lightweight placeholder.
      _user = User(
        id: 0,
        name: 'User',
        email: '',
        token: token!,
      );
    }
    notifyListeners();
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
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_useTempAuth) {
        // Temporary authentication with hardcoded credentials
        if (email == _tempUsername && password == _tempPassword) {
          _user = User(
            id: 1,
            name: 'Admin User',
            email: 'admin@finx.app',
            token: 'temp_admin_token',
          );
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          if (kDebugMode) {
            print('Temporary login successful: admin/admin');
          }
          return true;
        } else {
          throw Exception('Invalid credentials. Use admin/admin');
        }
      }
      
      // Real authentication (disabled for now)
      _user = await _apiService.login(email, password);
      _isAuthenticated = true;
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
  
  // Logout
  Future<void> logout() async {
    await _apiService.deleteToken();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
