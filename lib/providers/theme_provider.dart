import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode ON
  String _currency = 'USD';
  double _monthlyBudget = 5000.0; // Default budget
  bool _isInitialized = false;
  
  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  double get monthlyBudget => _monthlyBudget;
  bool get isInitialized => _isInitialized;
  
  ThemeProvider() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark
      _currency = prefs.getString('currency') ?? 'USD';
      _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 5000.0;
      _isInitialized = true;
      if (kDebugMode) {
        print('ThemeProvider loaded: Dark=$_isDarkMode');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading theme preferences: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      if (kDebugMode) {
        print('Theme toggled: Dark=$_isDarkMode');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling theme: $e');
      }
      // Revert on error
      _isDarkMode = !_isDarkMode;
    }
  }
  
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }
  
  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', budget);
    notifyListeners();
  }
  
  /// Set theme immediately without SharedPreferences (for testing)
  void setThemeImmediate(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
