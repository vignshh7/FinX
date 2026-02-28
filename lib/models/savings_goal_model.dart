class SavingsGoal {
  final String? id;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;
  final String? imageUrl;
  final SavingsGoalCategory category;
  final SavingsGoalPriority priority;
  final List<SavingsContribution> contributions;

  SavingsGoal({
    this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    this.updatedAt,
    this.isCompleted = false,
    this.imageUrl,
    required this.category,
    this.priority = SavingsGoalPriority.medium,
    this.contributions = const [],
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      targetAmount: (json['target_amount'] ?? 0.0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0.0).toDouble(),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : DateTime.now().add(const Duration(days: 365)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isCompleted: json['is_completed'] ?? false,
      imageUrl: json['image_url'],
      category: SavingsGoalCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] ?? 'general'),
        orElse: () => SavingsGoalCategory.general,
      ),
      priority: SavingsGoalPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (json['priority'] ?? 'medium'),
        orElse: () => SavingsGoalPriority.medium,
      ),
      contributions: json['contributions'] != null
          ? (json['contributions'] as List)
              .map((c) => SavingsContribution.fromJson(c))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_completed': isCompleted,
      'image_url': imageUrl,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'contributions': contributions.map((c) => c.toJson()).toList(),
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    String? imageUrl,
    SavingsGoalCategory? category,
    SavingsGoalPriority? priority,
    List<SavingsContribution>? contributions,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      contributions: contributions ?? this.contributions,
    );
  }

  // Helper methods
  double get progressPercentage {
    return targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  double get requiredMonthlyContribution {
    final monthsRemaining = daysRemaining / 30.0;
    return monthsRemaining > 0 ? remainingAmount / monthsRemaining : remainingAmount;
  }

  SavingsGoalStatus get status {
    if (isCompleted) return SavingsGoalStatus.completed;
    if (isOverdue) return SavingsGoalStatus.overdue;
    if (progressPercentage >= 0.9) return SavingsGoalStatus.nearCompletion;
    if (progressPercentage >= 0.5) return SavingsGoalStatus.onTrack;
    if (daysRemaining < 30) return SavingsGoalStatus.urgent;
    return SavingsGoalStatus.active;
  }
}

class SavingsContribution {
  final String? id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final SavingsContributionType type;

  SavingsContribution({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.type = SavingsContributionType.manual,
  });

  factory SavingsContribution.fromJson(Map<String, dynamic> json) {
    return SavingsContribution(
      id: json['id']?.toString(),
      goalId: json['goal_id']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      note: json['note'],
      type: SavingsContributionType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'manual'),
        orElse: () => SavingsContributionType.manual,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.toString().split('.').last,
    };
  }

  SavingsContribution copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? note,
    SavingsContributionType? type,
  }) {
    return SavingsContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }
}

enum SavingsGoalCategory {
  general,
  vacation,
  emergency,
  home,
  car,
  education,
  wedding,
  retirement,
  electronics,
  health,
  investment,
}

enum SavingsGoalPriority {
  low,
  medium,
  high,
  urgent,
}

enum SavingsGoalStatus {
  active,
  onTrack,
  nearCompletion,
  completed,
  overdue,
  urgent,
}

enum SavingsContributionType {
  manual,
  automatic,
  bonus,
  gift,
}

extension SavingsGoalCategoryExtension on SavingsGoalCategory {
  String get displayName {
    switch (this) {
      case SavingsGoalCategory.general:
        return 'General';
      case SavingsGoalCategory.vacation:
        return 'Vacation';
      case SavingsGoalCategory.emergency:
        return 'Emergency Fund';
      case SavingsGoalCategory.home:
        return 'Home';
      case SavingsGoalCategory.car:
        return 'Car';
      case SavingsGoalCategory.education:
        return 'Education';
      case SavingsGoalCategory.wedding:
        return 'Wedding';
      case SavingsGoalCategory.retirement:
        return 'Retirement';
      case SavingsGoalCategory.electronics:
        return 'Electronics';
      case SavingsGoalCategory.health:
        return 'Health';
      case SavingsGoalCategory.investment:
        return 'Investment';
    }
  }

  String get icon {
    switch (this) {
      case SavingsGoalCategory.general:
        return '💰';
      case SavingsGoalCategory.vacation:
        return '✈️';
      case SavingsGoalCategory.emergency:
        return '🏥';
      case SavingsGoalCategory.home:
        return '🏠';
      case SavingsGoalCategory.car:
        return '🚗';
      case SavingsGoalCategory.education:
        return '🎓';
      case SavingsGoalCategory.wedding:
        return '💒';
      case SavingsGoalCategory.retirement:
        return '🏖️';
      case SavingsGoalCategory.electronics:
        return '📱';
      case SavingsGoalCategory.health:
        return '💊';
      case SavingsGoalCategory.investment:
        return '📈';
    }
  }
}

extension SavingsGoalPriorityExtension on SavingsGoalPriority {
  String get displayName {
    switch (this) {
      case SavingsGoalPriority.low:
        return 'Low Priority';
      case SavingsGoalPriority.medium:
        return 'Medium Priority';
      case SavingsGoalPriority.high:
        return 'High Priority';
      case SavingsGoalPriority.urgent:
        return 'Urgent';
    }
  }
}

extension SavingsGoalStatusExtension on SavingsGoalStatus {
  String get displayName {
    switch (this) {
      case SavingsGoalStatus.active:
        return 'Active';
      case SavingsGoalStatus.onTrack:
        return 'On Track';
      case SavingsGoalStatus.nearCompletion:
        return 'Near Completion';
      case SavingsGoalStatus.completed:
        return 'Completed';
      case SavingsGoalStatus.overdue:
        return 'Overdue';
      case SavingsGoalStatus.urgent:
        return 'Urgent';
    }
  }
}