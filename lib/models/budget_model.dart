class Budget {
  final String? id;
  final String category;
  final double amount;
  final BudgetPeriod period;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final double? alertThreshold; // Percentage (0.0-1.0) when to show alerts
  final String? notes;
  final List<String>? tags;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.alertThreshold = 0.8, // Default 80%
    this.notes,
    this.tags,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id']?.toString(),
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == (json['period'] ?? 'monthly'),
        orElse: () => BudgetPeriod.monthly,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isActive: json['is_active'] ?? true,
      alertThreshold: json['alert_threshold']?.toDouble() ?? 0.8,
      notes: json['notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'alert_threshold': alertThreshold,
      'notes': notes,
      'tags': tags,
    };
  }

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    BudgetPeriod? period,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? alertThreshold,
    String? notes,
    List<String>? tags,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods
  bool shouldAlert(double spentAmount) {
    if (alertThreshold == null) return false;
    return (spentAmount / amount) >= alertThreshold!;
  }

  double getRemainingAmount(double spentAmount) {
    return amount - spentAmount;
  }

  double getSpentPercentage(double spentAmount) {
    return amount > 0 ? (spentAmount / amount) : 0.0;
  }

  BudgetStatus getStatus(double spentAmount) {
    final percentage = getSpentPercentage(spentAmount);
    
    if (percentage >= 1.0) return BudgetStatus.exceeded;
    if (alertThreshold != null && percentage >= alertThreshold!) return BudgetStatus.warning;
    if (percentage >= 0.5) return BudgetStatus.onTrack;
    return BudgetStatus.underUsed;
  }
}

enum BudgetPeriod {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

enum BudgetStatus {
  underUsed,
  onTrack,
  warning,
  exceeded,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.biweekly:
        return 'Bi-weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  int get days {
    switch (this) {
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.biweekly:
        return 14;
      case BudgetPeriod.monthly:
        return 30;
      case BudgetPeriod.quarterly:
        return 90;
      case BudgetPeriod.yearly:
        return 365;
    }
  }
}

extension BudgetStatusExtension on BudgetStatus {
  String get displayName {
    switch (this) {
      case BudgetStatus.underUsed:
        return 'Under Used';
      case BudgetStatus.onTrack:
        return 'On Track';
      case BudgetStatus.warning:
        return 'Warning';
      case BudgetStatus.exceeded:
        return 'Over Budget';
    }
  }
}
