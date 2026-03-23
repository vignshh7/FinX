class BillReminder {
  final String? id;
  final String title;
  final String? description;
  final double amount;
  final DateTime dueDate;
  final BillFrequency frequency;
  final BillCategory category;
  final BillPriority priority;
  final bool isRecurring;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? notes;
  final List<String>? tags;
  final BillStatus status;

  BillReminder({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.dueDate,
    required this.frequency,
    required this.category,
    this.priority = BillPriority.medium,
    this.isRecurring = false,
    this.isPaid = false,
    required this.createdAt,
    this.updatedAt,
    this.paidDate,
    this.paymentMethod,
    this.notes,
    this.tags,
    this.status = BillStatus.pending,
  });

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  factory BillReminder.fromJson(Map<String, dynamic> json) {
    return BillReminder(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.now(),
      frequency: BillFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == (json['frequency'] ?? 'monthly'),
        orElse: () => BillFrequency.monthly,
      ),
      category: BillCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] ?? 'utilities'),
        orElse: () => BillCategory.utilities,
      ),
      priority: BillPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (json['priority'] ?? 'medium'),
        orElse: () => BillPriority.medium,
      ),
      isRecurring: _toBool(json['is_recurring']),
      isPaid: _toBool(json['is_paid']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'])
          : null,
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      status: BillStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => BillStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.toString().split('.').last,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'is_recurring': isRecurring,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'tags': tags,
      'status': status.toString().split('.').last,
    };
  }

  BillReminder copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    DateTime? dueDate,
    BillFrequency? frequency,
    BillCategory? category,
    BillPriority? priority,
    bool? isRecurring,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidDate,
    String? paymentMethod,
    String? notes,
    List<String>? tags,
    BillStatus? status,
  }) {
    return BillReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRecurring: isRecurring ?? this.isRecurring,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }

  // Helper methods
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  bool get isOverdue {
    return daysUntilDue < 0 && !isPaid;
  }

  bool get isDueToday {
    return daysUntilDue == 0 && !isPaid;
  }

  bool get isDueSoon {
    return daysUntilDue <= 3 && daysUntilDue > 0 && !isPaid;
  }

  BillUrgency get urgency {
    if (isPaid) return BillUrgency.paid;
    if (isOverdue) return BillUrgency.overdue;
    if (isDueToday) return BillUrgency.dueToday;
    if (isDueSoon) return BillUrgency.dueSoon;
    return BillUrgency.normal;
  }

  DateTime? get nextDueDate {
    if (!isRecurring) return null;
    
    final now = DateTime.now();
    DateTime nextDate = dueDate;
    
    while (nextDate.isBefore(now)) {
      switch (frequency) {
        case BillFrequency.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case BillFrequency.biweekly:
          nextDate = nextDate.add(const Duration(days: 14));
          break;
        case BillFrequency.monthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case BillFrequency.quarterly:
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
          break;
        case BillFrequency.semiannually:
          nextDate = DateTime(nextDate.year, nextDate.month + 6, nextDate.day);
          break;
        case BillFrequency.annually:
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        case BillFrequency.oneTime:
          return null;
      }
    }
    
    return nextDate;
  }

  double get annualAmount {
    switch (frequency) {
      case BillFrequency.weekly:
        return amount * 52;
      case BillFrequency.biweekly:
        return amount * 26;
      case BillFrequency.monthly:
        return amount * 12;
      case BillFrequency.quarterly:
        return amount * 4;
      case BillFrequency.semiannually:
        return amount * 2;
      case BillFrequency.annually:
      case BillFrequency.oneTime:
        return amount;
    }
  }
}

enum BillFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannually,
  annually,
  oneTime,
}

enum BillCategory {
  utilities,
  housing,
  insurance,
  subscriptions,
  loans,
  creditCards,
  taxes,
  healthcare,
  transportation,
  education,
  entertainment,
  other,
}

enum BillPriority {
  low,
  medium,
  high,
  critical,
}

enum BillStatus {
  pending,
  paid,
  overdue,
  partiallyPaid,
  cancelled,
}

enum BillUrgency {
  paid,
  normal,
  dueSoon,
  dueToday,
  overdue,
}

extension BillFrequencyExtension on BillFrequency {
  String get displayName {
    switch (this) {
      case BillFrequency.weekly:
        return 'Weekly';
      case BillFrequency.biweekly:
        return 'Bi-weekly';
      case BillFrequency.monthly:
        return 'Monthly';
      case BillFrequency.quarterly:
        return 'Quarterly';
      case BillFrequency.semiannually:
        return 'Semi-annually';
      case BillFrequency.annually:
        return 'Annually';
      case BillFrequency.oneTime:
        return 'One-time';
    }
  }
}

extension BillCategoryExtension on BillCategory {
  String get displayName {
    switch (this) {
      case BillCategory.utilities:
        return 'Utilities';
      case BillCategory.housing:
        return 'Housing';
      case BillCategory.insurance:
        return 'Insurance';
      case BillCategory.subscriptions:
        return 'Subscriptions';
      case BillCategory.loans:
        return 'Loans';
      case BillCategory.creditCards:
        return 'Credit Cards';
      case BillCategory.taxes:
        return 'Taxes';
      case BillCategory.healthcare:
        return 'Healthcare';
      case BillCategory.transportation:
        return 'Transportation';
      case BillCategory.education:
        return 'Education';
      case BillCategory.entertainment:
        return 'Entertainment';
      case BillCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case BillCategory.utilities:
        return '⚡';
      case BillCategory.housing:
        return '🏠';
      case BillCategory.insurance:
        return '🛡️';
      case BillCategory.subscriptions:
        return '📱';
      case BillCategory.loans:
        return '🏦';
      case BillCategory.creditCards:
        return '💳';
      case BillCategory.taxes:
        return '📋';
      case BillCategory.healthcare:
        return '🏥';
      case BillCategory.transportation:
        return '🚗';
      case BillCategory.education:
        return '🎓';
      case BillCategory.entertainment:
        return '🎬';
      case BillCategory.other:
        return '📄';
    }
  }
}

extension BillPriorityExtension on BillPriority {
  String get displayName {
    switch (this) {
      case BillPriority.low:
        return 'Low Priority';
      case BillPriority.medium:
        return 'Medium Priority';
      case BillPriority.high:
        return 'High Priority';
      case BillPriority.critical:
        return 'Critical';
    }
  }
}

extension BillStatusExtension on BillStatus {
  String get displayName {
    switch (this) {
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.overdue:
        return 'Overdue';
      case BillStatus.partiallyPaid:
        return 'Partially Paid';
      case BillStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension BillUrgencyExtension on BillUrgency {
  String get displayName {
    switch (this) {
      case BillUrgency.paid:
        return 'Paid';
      case BillUrgency.normal:
        return 'Normal';
      case BillUrgency.dueSoon:
        return 'Due Soon';
      case BillUrgency.dueToday:
        return 'Due Today';
      case BillUrgency.overdue:
        return 'Overdue';
    }
  }
}