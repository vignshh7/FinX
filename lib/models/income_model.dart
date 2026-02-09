class Income {
  final String id;
  final String userId;
  final String source;
  final double amount;
  final DateTime date;
  final String category;
  final bool isRecurring;
  final String? notes;

  Income({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.date,
    required this.category,
    this.isRecurring = false,
    this.notes,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      source: json['source'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      category: json['category'] ?? 'Other',
      isRecurring: json['is_recurring'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'source': source,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'is_recurring': isRecurring,
      'notes': notes,
    };
  }
}

class IncomeCategory {
  static const salary = 'Salary';
  static const freelance = 'Freelance';
  static const investment = 'Investment';
  static const business = 'Business';
  static const rental = 'Rental';
  static const gift = 'Gift';
  static const other = 'Other';

  static const List<String> allCategories = [
    salary,
    freelance,
    investment,
    business,
    rental,
    gift,
    other,
  ];
}
