class Budget {
  final int? id;
  final int userId;
  final double monthlyLimit;
  final String currency;

  Budget({
    this.id,
    required this.userId,
    required this.monthlyLimit,
    required this.currency,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'monthly_limit': monthlyLimit,
      'currency': currency,
    };
  }
}
