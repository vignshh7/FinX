import 'package:flutter/foundation.dart';
import '../models/bill_reminder_model.dart';
import '../services/api_service.dart';

class BillReminderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BillReminder> _bills = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BillReminder> get bills => List.unmodifiable(_bills);

  List<BillReminder> get upcomingBills => _bills
      .where((b) => !b.isPaid && b.daysUntilDue >= 0)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<BillReminder> get overdueBills => _bills
      .where((b) => b.isOverdue)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<BillReminder> get paidBills => _bills
      .where((b) => b.isPaid)
      .toList()
    ..sort((a, b) =>
        (b.paidDate ?? DateTime.now()).compareTo(a.paidDate ?? DateTime.now()));

  List<BillReminder> get pendingBills => _bills
      .where((b) => !b.isPaid)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  double get totalUpcomingAmount =>
      upcomingBills.fold(0.0, (s, b) => s + b.amount);

  double get totalOverdueAmount =>
      overdueBills.fold(0.0, (s, b) => s + b.amount);

  double get monthlyBillsAmount {
    final now = DateTime.now();
    return _bills
        .where((b) => b.dueDate.year == now.year && b.dueDate.month == now.month)
        .fold(0.0, (s, b) => s + b.amount);
  }

  //  fetch 

  Future<void> fetchBillReminders({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getBillReminders();
      _bills = data.map((d) => BillReminder.fromJson(d)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('fetchBillReminders error: $e');
      if (_bills.isEmpty) _bills = _getSampleBills();
    }
    _isLoading = false;
    notifyListeners();
  }

  //  mark as paid 

  Future<bool> markBillAsPaid(String billId, {String? paymentMethod}) async {
    final idx = _bills.indexWhere((b) => b.id == billId);
    if (idx == -1) return false;

    // Step 1: instant local update with a fresh list so Flutter detects the change
    final paid = _bills[idx].copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
      paymentMethod: paymentMethod,
      status: BillStatus.paid,
      updatedAt: DateTime.now(),
    );
    _bills = [
      for (int i = 0; i < _bills.length; i++) i == idx ? paid : _bills[i],
    ];
    notifyListeners(); // bill leaves Upcoming/Overdue immediately, count drops

    // Step 2: persist to DB
    try {
      await _apiService.markBillAsPaid(billId, paymentMethod);
    } catch (e) {
      debugPrint('markBillAsPaid API error (local update kept): $e');
      return true; // keep optimistic update
    }

    // Step 3: handle recurring bills
    if (paid.isRecurring) {
      await _createNextRecurringBill(paid);
    }

    // Step 4: re-fetch from server so every count and tab is definitively correct
    await fetchBillReminders(forceRefresh: true);
    return true;
  }

  //  add 

  Future<bool> addBillReminder(BillReminder bill) async {
    try {
      final result = await _apiService.createBillReminder(bill.toJson());
      final billData = result.containsKey('bill') ? result['bill'] : result;
      if ((billData as Map<String, dynamic>).containsKey('id')) {
        _bills = [..._bills, BillReminder.fromJson(billData)];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('addBillReminder error: $e');
    }
    _bills = [
      ..._bills,
      bill.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()),
    ];
    notifyListeners();
    return true;
  }

  //  update 

  Future<bool> updateBillReminder(BillReminder bill) async {
    try {
      final result =
          await _apiService.updateBillReminder(bill.id!, bill.toJson());
      final billData = result.containsKey('bill') ? result['bill'] : result;
      final idx = _bills.indexWhere((b) => b.id == bill.id);
      if (idx != -1) {
        final updated = (billData as Map<String, dynamic>).containsKey('id')
            ? BillReminder.fromJson(billData)
            : bill;
        _bills = [
          for (int i = 0; i < _bills.length; i++) i == idx ? updated : _bills[i],
        ];
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('updateBillReminder error: $e');
      final idx = _bills.indexWhere((b) => b.id == bill.id);
      if (idx != -1) {
        _bills = [
          for (int i = 0; i < _bills.length; i++) i == idx ? bill : _bills[i],
        ];
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  //  delete 

  Future<bool> deleteBillReminder(String billId) async {
    try {
      await _apiService.deleteBillReminder(billId);
    } catch (e) {
      debugPrint('deleteBillReminder error: $e');
    }
    _bills = _bills.where((b) => b.id != billId).toList();
    notifyListeners();
    return true;
  }

  //  helpers 

  Future<void> _createNextRecurringBill(BillReminder paidBill) async {
    if (!paidBill.isRecurring || paidBill.frequency == BillFrequency.oneTime) {
      return;
    }
    final nextDueDate = paidBill.nextDueDate;
    if (nextDueDate == null) return;
    await addBillReminder(paidBill.copyWith(
      id: null,
      dueDate: nextDueDate,
      isPaid: false,
      paidDate: null,
      paymentMethod: null,
      status: BillStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: null,
    ));
  }

  BillReminder? getBillById(String billId) {
    try {
      return _bills.firstWhere((b) => b.id == billId);
    } catch (_) {
      return null;
    }
  }

  void invalidateCache() {}

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<BillCategory, double> getBillCategoryTotals() {
    final totals = <BillCategory, double>{};
    for (final b in _bills.where((b) => !b.isPaid)) {
      totals[b.category] = (totals[b.category] ?? 0.0) + b.amount;
    }
    return totals;
  }

  double getProjectedMonthlyTotal() {
    double total = 0;
    for (final b in _bills.where((b) => !b.isPaid)) {
      switch (b.frequency) {
        case BillFrequency.weekly:
          total += b.amount * 4.33;
          break;
        case BillFrequency.biweekly:
          total += b.amount * 2.17;
          break;
        case BillFrequency.monthly:
          total += b.amount;
          break;
        case BillFrequency.quarterly:
          total += b.amount / 3;
          break;
        case BillFrequency.semiannually:
          total += b.amount / 6;
          break;
        case BillFrequency.annually:
          total += b.amount / 12;
          break;
        case BillFrequency.oneTime:
          if (b.daysUntilDue <= 30) total += b.amount;
          break;
      }
    }
    return total;
  }

  List<String> getBillInsights() {
    final insights = <String>[];
    final overdueCount = overdueBills.length;
    if (overdueCount > 0) {
      insights.add('You have $overdueCount overdue '
          '${overdueCount == 1 ? "bill" : "bills"} totaling '
          '\$${totalOverdueAmount.toStringAsFixed(2)}.');
    }
    final upcomingCount = upcomingBills.length;
    if (upcomingCount > 0) {
      insights.add('$upcomingCount '
          '${upcomingCount == 1 ? "bill is" : "bills are"} due soon.');
    }
    insights.add('Your projected monthly bills total '
        '\$${getProjectedMonthlyTotal().toStringAsFixed(2)}.');
    final categoryTotals = getBillCategoryTotals();
    if (categoryTotals.isNotEmpty) {
      final top =
          categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('${top.key.displayName} is your largest category at '
          '\$${top.value.toStringAsFixed(2)}.');
    }
    final paidCount = paidBills.length;
    final totalCount = _bills.length;
    if (totalCount > 0) {
      final rate = (paidCount / totalCount * 100).round();
      if (rate >= 90) {
        insights.add('Excellent payment history! You\'ve paid $rate% of your bills.');
      } else if (rate >= 70) {
        insights.add('Good consistency at $rate%. Consider automatic payments.');
      } else {
        insights.add('Focus on improving payment consistency.');
      }
    }
    return insights;
  }

  List<BillReminder> _getSampleBills() {
    return [
      BillReminder(
        id: '1',
        title: 'Electricity Bill',
        description: 'Monthly electricity payment',
        amount: 120.50,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        frequency: BillFrequency.monthly,
        category: BillCategory.utilities,
        priority: BillPriority.high,
        isRecurring: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      BillReminder(
        id: '2',
        title: 'Internet Bill',
        description: 'High-speed internet service',
        amount: 79.99,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        frequency: BillFrequency.monthly,
        category: BillCategory.utilities,
        priority: BillPriority.medium,
        isRecurring: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      BillReminder(
        id: '3',
        title: 'Credit Card Payment',
        description: 'Minimum payment due',
        amount: 350.00,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        frequency: BillFrequency.monthly,
        category: BillCategory.creditCards,
        priority: BillPriority.critical,
        isRecurring: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        status: BillStatus.overdue,
      ),
      BillReminder(
        id: '4',
        title: 'Netflix Subscription',
        description: 'Monthly streaming service',
        amount: 15.99,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        frequency: BillFrequency.monthly,
        category: BillCategory.subscriptions,
        priority: BillPriority.low,
        isRecurring: true,
        isPaid: true,
        paidDate: DateTime.now().subtract(const Duration(days: 5)),
        status: BillStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      BillReminder(
        id: '5',
        title: 'Car Insurance',
        description: 'Semi-annual auto insurance premium',
        amount: 650.00,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        frequency: BillFrequency.semiannually,
        category: BillCategory.insurance,
        priority: BillPriority.high,
        isRecurring: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      BillReminder(
        id: '6',
        title: 'Gym Membership',
        description: 'Monthly fitness club membership',
        amount: 49.99,
        dueDate: DateTime.now(),
        frequency: BillFrequency.monthly,
        category: BillCategory.healthcare,
        priority: BillPriority.medium,
        isRecurring: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }
}
