import 'dart:math';
import 'services/api_service.dart';
import 'models/expense_model.dart';
import 'models/income_model.dart';
import 'models/category_model.dart';

/// Test data populator class to add comprehensive sample data via API calls
class TestDataPopulator {
  final ApiService _apiService = ApiService();
  final Random _random = Random();
  void Function(String)? _logCallback;

  /// Set a callback to capture log messages
  void setLogCallback(void Function(String) callback) {
    _logCallback = callback;
  }

  /// Log a message (either to callback or print)
  void _log(String message) {
    if (_logCallback != null) {
      _logCallback!(message);
    } else {
      print(message);
    }
  }

  /// Populate account with comprehensive test data
  Future<void> populateTestData() async {
    try {
      _log('🚀 Starting test data population...');
      
      // Add expenses (last 6 months)
      await _addTestExpenses();
      
      // Add income records
      await _addTestIncome();
      
      // Add budgets
      await _addTestBudgets();
      
      // Add savings goals
      await _addTestSavingsGoals();
      
      // Add bill reminders
      await _addTestBillReminders();
      
      _log('✅ Test data population completed successfully!');
    } catch (e) {
      _log('❌ Error populating test data: $e');
    }
  }

  /// Add realistic expense data for the last 6 months
  Future<void> _addTestExpenses() async {
    _log('💰 Adding test expenses...');
    
    final now = DateTime.now();
    final expenses = <Expense>[];

    // Generate expenses for last 6 months
    for (int monthOffset = 0; monthOffset < 6; monthOffset++) {
      final month = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      
      // Add 15-25 expenses per month
      final expenseCount = 15 + _random.nextInt(11);
      
      for (int i = 0; i < expenseCount; i++) {
        final day = 1 + _random.nextInt(daysInMonth);
        final expenseDate = DateTime(month.year, month.month, day);
        
        expenses.add(_generateRandomExpense(expenseDate));
      }
    }

    // Add expenses via API
    for (final expense in expenses) {
      try {
        await _apiService.createExpense(expense);
        await Future.delayed(const Duration(milliseconds: 100)); // Rate limiting
      } catch (e) {
        _log('Error adding expense: $e');
      }
    }
    
    _log('✅ Added ${expenses.length} test expenses');
  }

  /// Generate a random realistic expense
  Expense _generateRandomExpense(DateTime date) {
    final categories = ExpenseCategory.all;
    final category = categories[_random.nextInt(categories.length)];
    
    final storeAndAmount = _getStoreAndAmountForCategory(category);
    
    return Expense(
      userId: 1, // Will be overridden by backend with actual user ID
      store: storeAndAmount['store']!,
      amount: storeAndAmount['amount']!,
      category: category,
      date: date,
      items: _getItemsForCategory(category),
      rawOcrText: null,
    );
  }

  /// Get realistic store names and amounts based on category
  Map<String, dynamic> _getStoreAndAmountForCategory(String category) {
    switch (category) {
      case ExpenseCategory.food:
        final stores = [
          'McDonald\'s', 'Starbucks', 'Subway', 'Pizza Hut', 'KFC',
          'Domino\'s', 'Local Restaurant', 'Cafe Central', 'Burger King',
          'Taco Bell', 'Food Court', 'Street Food', 'Fine Dining'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 8.0 + _random.nextDouble() * 47.0, // $8-55
        };
        
      case ExpenseCategory.travel:
        final stores = [
          'Uber', 'Lyft', 'Gas Station', 'Shell', 'Chevron',
          'Public Transport', 'Taxi', 'Airport Parking', 'Car Rental',
          'Bus Ticket', 'Train Ticket', 'Flight Booking'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 15.0 + _random.nextDouble() * 185.0, // $15-200
        };
        
      case ExpenseCategory.shopping:
        final stores = [
          'Amazon', 'Target', 'Walmart', 'Best Buy', 'Apple Store',
          'Nike', 'Zara', 'H&M', 'Macy\'s', 'Online Store',
          'Local Shop', 'Mall Purchase', 'Electronics Store'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 25.0 + _random.nextDouble() * 275.0, // $25-300
        };
        
      case ExpenseCategory.bills:
        final stores = [
          'Electric Company', 'Water Utility', 'Internet Provider',
          'Phone Bill', 'Insurance', 'Rent Payment', 'Mortgage',
          'Credit Card Payment', 'Loan Payment'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 50.0 + _random.nextDouble() * 450.0, // $50-500
        };
        
      case ExpenseCategory.entertainment:
        final stores = [
          'Netflix', 'Spotify', 'Movie Theater', 'Concert Ticket',
          'Game Purchase', 'Streaming Service', 'Event Ticket',
          'Amusement Park', 'Sports Event', 'Theater Show'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 10.0 + _random.nextDouble() * 90.0, // $10-100
        };
        
      default: // Other
        final stores = [
          'Medical', 'Pharmacy', 'Gym', 'Hair Salon', 'Pet Store',
          'Gift Shop', 'Charity', 'Miscellaneous', 'Health & Beauty'
        ];
        return {
          'store': stores[_random.nextInt(stores.length)],
          'amount': 20.0 + _random.nextDouble() * 80.0, // $20-100
        };
    }
  }

  /// Get realistic items for category
  List<String> _getItemsForCategory(String category) {
    switch (category) {
      case ExpenseCategory.food:
        return ['Meal', 'Drink', 'Snack'];
      case ExpenseCategory.travel:
        return ['Transportation'];
      case ExpenseCategory.shopping:
        return ['Purchase'];
      case ExpenseCategory.bills:
        return ['Utility', 'Service'];
      case ExpenseCategory.entertainment:
        return ['Subscription', 'Ticket'];
      default:
        return ['Item'];
    }
  }

  /// Add realistic income data
  Future<void> _addTestIncome() async {
    _log('💵 Adding test income...');
    
    final now = DateTime.now();
    final incomes = <Map<String, dynamic>>[];

    // Add monthly salary for last 6 months
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 25); // Salary on 25th
      incomes.add({
        'source': 'Monthly Salary',
        'amount': 4500.0 + _random.nextDouble() * 1500.0, // $4500-6000
        'currency': 'USD',
        'date': date.toIso8601String(),
        'category': IncomeCategory.salary,
        'is_recurring': true,
        'notes': 'Regular monthly salary',
      });
    }

    // Add freelance income (sporadic)
    for (int i = 0; i < 8; i++) {
      final date = DateTime(
        now.year,
        now.month - _random.nextInt(6),
        1 + _random.nextInt(28),
      );
      incomes.add({
        'source': 'Freelance Project',
        'amount': 200.0 + _random.nextDouble() * 1300.0, // $200-1500
        'currency': 'USD',
        'date': date.toIso8601String(),
        'category': IncomeCategory.freelance,
        'is_recurring': false,
        'notes': 'Project-based work',
      });
    }

    // Add investment returns
    for (int i = 0; i < 3; i++) {
      final date = DateTime(
        now.year,
        now.month - _random.nextInt(3),
        1 + _random.nextInt(28),
      );
      incomes.add({
        'source': 'Investment Returns',
        'amount': 50.0 + _random.nextDouble() * 450.0, // $50-500
        'currency': 'USD',
        'date': date.toIso8601String(),
        'category': IncomeCategory.investment,
        'is_recurring': false,
        'notes': 'Dividend and interest',
      });
    }

    // Add bonuses
    incomes.add({
      'source': 'Year-end Bonus',
      'amount': 2000.0 + _random.nextDouble() * 3000.0, // $2000-5000
      'currency': 'USD',
      'date': DateTime(now.year - 1, 12, 20).toIso8601String(),
      'category': IncomeCategory.other,
      'is_recurring': false,
      'notes': 'Annual performance bonus',
    });

    // Add side hustle income
    for (int i = 0; i < 5; i++) {
      final date = DateTime(
        now.year,
        now.month - _random.nextInt(4),
        1 + _random.nextInt(28),
      );
      incomes.add({
        'source': 'Side Business',
        'amount': 100.0 + _random.nextDouble() * 400.0, // $100-500
        'currency': 'USD',
        'date': date.toIso8601String(),
        'category': IncomeCategory.business,
        'is_recurring': false,
        'notes': 'Online business income',
      });
    }

    // Add via API
    for (final income in incomes) {
      try {
        await _apiService.addIncome(income);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _log('Error adding income: $e');
      }
    }
    
    _log('✅ Added ${incomes.length} test income records');
  }

  /// Add test budget data
  Future<void> _addTestBudgets() async {
    _log('🎯 Adding test budgets...');
    
    final budgets = [
      {
        'category': ExpenseCategory.food,
        'amount': 800.0,
        'period': 'monthly',
        'alert_threshold': 0.8,
        'notes': 'Monthly food and dining budget',
      },
      {
        'category': ExpenseCategory.travel,
        'amount': 300.0,
        'period': 'monthly',
        'alert_threshold': 0.9,
        'notes': 'Transportation and travel expenses',
      },
      {
        'category': ExpenseCategory.shopping,
        'amount': 500.0,
        'period': 'monthly',
        'alert_threshold': 0.75,
        'notes': 'Shopping and personal items',
      },
      {
        'category': ExpenseCategory.entertainment,
        'amount': 200.0,
        'period': 'monthly',
        'alert_threshold': 0.8,
        'notes': 'Entertainment and subscriptions',
      },
      {
        'category': ExpenseCategory.bills,
        'amount': 1500.0,
        'period': 'monthly',
        'alert_threshold': 0.95,
        'notes': 'Utilities and recurring bills',
      },
    ];

    for (final budget in budgets) {
      try {
        await _apiService.createBudget(budget);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _log('Error adding budget: $e');
      }
    }
    
    _log('✅ Added ${budgets.length} test budgets');
  }

  /// Add test savings goals
  Future<void> _addTestSavingsGoals() async {
    _log('🎯 Adding test savings goals...');
    
    final now = DateTime.now();
    final goals = [
      {
        'title': 'Emergency Fund',
        'description': 'Build a 6-month emergency fund for financial security',
        'target_amount': 15000.0,
        'current_amount': 8500.0,
        'target_date': now.add(const Duration(days: 180)).toIso8601String(),
        'category': 'emergency',
        'priority': 'high',
      },
      {
        'title': 'Dream Vacation to Japan',
        'description': 'Two weeks exploring Tokyo, Kyoto, and Osaka',
        'target_amount': 5000.0,
        'current_amount': 2200.0,
        'target_date': now.add(const Duration(days: 300)).toIso8601String(),
        'category': 'vacation',
        'priority': 'medium',
      },
      {
        'title': 'New Car Down Payment',
        'description': 'Save for a reliable used car',
        'target_amount': 8000.0,
        'current_amount': 3200.0,
        'target_date': now.add(const Duration(days: 365)).toIso8601String(),
        'category': 'car',
        'priority': 'high',
      },
      {
        'title': 'Home Renovation',
        'description': 'Kitchen and bathroom upgrade',
        'target_amount': 12000.0,
        'current_amount': 4800.0,
        'target_date': now.add(const Duration(days: 540)).toIso8601String(),
        'category': 'home',
        'priority': 'medium',
      },
      {
        'title': 'Investment Portfolio',
        'description': 'Build diversified investment portfolio',
        'target_amount': 10000.0,
        'current_amount': 2500.0,
        'target_date': now.add(const Duration(days: 720)).toIso8601String(),
        'category': 'investment',
        'priority': 'medium',
      },
      {
        'title': 'New Laptop',
        'description': 'MacBook Pro for work and personal use',
        'target_amount': 2500.0,
        'current_amount': 2500.0,
        'target_date': now.subtract(const Duration(days: 10)).toIso8601String(),
        'category': 'electronics',
        'priority': 'medium',
        'is_completed': true,
      },
    ];

    for (final goal in goals) {
      try {
        await _apiService.createSavingsGoal(goal);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _log('Error adding savings goal: $e');
      }
    }
    
    _log('✅ Added ${goals.length} test savings goals');
  }

  /// Add test bill reminders
  Future<void> _addTestBillReminders() async {
    _log('📋 Adding test bill reminders...');
    
    final now = DateTime.now();
    final bills = [
      {
        'title': 'Electricity Bill',
        'description': 'Monthly electricity payment - City Power Company',
        'amount': 120.50,
        'due_date': now.add(const Duration(days: 2)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'utilities',
        'priority': 'high',
        'is_recurring': true,
      },
      {
        'title': 'Internet & Cable',
        'description': 'High-speed internet and cable TV package',
        'amount': 89.99,
        'due_date': now.add(const Duration(days: 5)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'utilities',
        'priority': 'medium',
        'is_recurring': true,
      },
      {
        'title': 'Credit Card Payment',
        'description': 'Minimum payment due - Chase Sapphire',
        'amount': 350.00,
        'due_date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'credit_cards',
        'priority': 'critical',
        'is_recurring': true,
        'status': 'overdue',
      },
      {
        'title': 'Netflix Subscription',
        'description': 'Monthly streaming service',
        'amount': 15.99,
        'due_date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'subscriptions',
        'priority': 'low',
        'is_recurring': true,
        'is_paid': true,
        'paid_date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'status': 'paid',
      },
      {
        'title': 'Car Insurance',
        'description': 'Semi-annual auto insurance premium - State Farm',
        'amount': 650.00,
        'due_date': now.add(const Duration(days: 15)).toIso8601String(),
        'frequency': 'semiannually',
        'category': 'insurance',
        'priority': 'high',
        'is_recurring': true,
      },
      {
        'title': 'Gym Membership',
        'description': 'Monthly fitness club membership - Planet Fitness',
        'amount': 49.99,
        'due_date': now.toIso8601String(),
        'frequency': 'monthly',
        'category': 'healthcare',
        'priority': 'medium',
        'is_recurring': true,
      },
      {
        'title': 'Spotify Premium',
        'description': 'Music streaming service',
        'amount': 9.99,
        'due_date': now.add(const Duration(days: 12)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'subscriptions',
        'priority': 'low',
        'is_recurring': true,
      },
      {
        'title': 'Water Bill',
        'description': 'Quarterly water and sewer service',
        'amount': 85.75,
        'due_date': now.add(const Duration(days: 20)).toIso8601String(),
        'frequency': 'quarterly',
        'category': 'utilities',
        'priority': 'high',
        'is_recurring': true,
      },
      {
        'title': 'Health Insurance',
        'description': 'Monthly health insurance premium',
        'amount': 285.00,
        'due_date': now.add(const Duration(days: 8)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'healthcare',
        'priority': 'critical',
        'is_recurring': true,
      },
      {
        'title': 'Phone Bill',
        'description': 'Mobile phone service - Verizon',
        'amount': 75.50,
        'due_date': now.add(const Duration(days: 18)).toIso8601String(),
        'frequency': 'monthly',
        'category': 'utilities',
        'priority': 'medium',
        'is_recurring': true,
      },
    ];

    for (final bill in bills) {
      try {
        await _apiService.createBillReminder(bill);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        _log('Error adding bill reminder: $e');
      }
    }
    
    _log('✅ Added ${bills.length} test bill reminders');
  }
}