class Subscription {
  final int? id;
  final int userId;
  final String name;
  final double amount;
  final String frequency; // monthly, yearly
  final DateTime renewalDate;

  Subscription({
    this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.renewalDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'],
      renewalDate: DateTime.parse(json['renewal_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'renewal_date': renewalDate.toIso8601String(),
    };
  }

  double get monthlyAmount {
    return frequency == 'yearly' ? amount / 12 : amount;
  }
}
