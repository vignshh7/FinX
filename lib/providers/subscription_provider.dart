import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;
  
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch subscriptions
  Future<void> fetchSubscriptions() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _subscriptions = await _apiService.getSubscriptions();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add subscription
  Future<bool> addSubscription(Subscription subscription) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newSubscription = await _apiService.createSubscription(subscription);
      _subscriptions.add(newSubscription);
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
  
  // Delete subscription
  Future<bool> deleteSubscription(int id) async {
    try {
      await _apiService.deleteSubscription(id);
      _subscriptions.removeWhere((sub) => sub.id == id);
      notifyListeners();
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
}
