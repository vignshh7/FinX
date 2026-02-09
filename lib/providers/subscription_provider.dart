import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  
  // Cache timestamp for smart API calls
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Check if cache is still valid
  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }
  
  // Fetch subscriptions with caching
  Future<void> fetchSubscriptions({bool forceRefresh = false}) async {
    // Skip if cache is valid and no force refresh
    if (!forceRefresh && _isCacheValid()) {
      if (kDebugMode) {
        print('Using cached subscriptions data');
      }
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _subscriptions = await _apiService.getSubscriptions();
      _lastFetch = DateTime.now();
      _error = null;
      if (kDebugMode) {
        print('Subscriptions fetched: ${_subscriptions.length} items');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching subscriptions: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add subscription - invalidate cache
  Future<bool> addSubscription(Subscription subscription) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newSubscription = await _apiService.createSubscription(subscription);
      _subscriptions.add(newSubscription);
      _lastFetch = null; // Invalidate cache
      _error = null;
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Subscription added successfully, cache invalidated');
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete subscription - invalidate cache
  Future<bool> deleteSubscription(int id) async {
    try {
      await _apiService.deleteSubscription(id);
      _subscriptions.removeWhere((sub) => sub.id == id);
      _lastFetch = null; // Invalidate cache
      notifyListeners();
      if (kDebugMode) {
        print('Subscription deleted successfully, cache invalidated');
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Calculate total monthly cost
  double get totalMonthlyCost {
    return _subscriptions.fold(0.0, (sum, sub) => sum + sub.monthlyAmount);
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear all cached data (call on logout)
  void clearCache() {
    _subscriptions = [];
    _lastFetch = null;
    _error = null;
    notifyListeners();
    if (kDebugMode) {
      print('SubscriptionProvider cache cleared');
    }
  }
}
