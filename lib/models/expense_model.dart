class Expense {
  final int? id;
  final int userId;
  final String store;
  final double amount;
  final String category;
  final DateTime date;
  final List<String>? items;
  final String? rawOcrText;

  Expense({
    this.id,
    required this.userId,
    required this.store,
    required this.amount,
    required this.category,
    required this.date,
    this.items,
    this.rawOcrText,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      store: json['store'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
      items: json['items'] != null ? List<String>.from(json['items']) : null,
      rawOcrText: json['raw_ocr_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store': store,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'items': items,
      'raw_ocr_text': rawOcrText,
    };
  }
}
