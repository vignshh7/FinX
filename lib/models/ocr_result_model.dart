class OCRResult {
  final String store;
  final List<String> items;
  final double amount;
  final String date;
  final String predictedCategory;
  final double confidence;
  final String rawText;

  OCRResult({
    required this.store,
    required this.items,
    required this.amount,
    required this.date,
    required this.predictedCategory,
    required this.confidence,
    required this.rawText,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      store: json['store'] ?? 'Unknown Store',
      items: json['items'] != null ? List<String>.from(json['items']) : [],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      predictedCategory: json['predicted_category'] ?? 'Other',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawText: json['raw_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store': store,
      'items': items,
      'amount': amount,
      'date': date,
      'predicted_category': predictedCategory,
      'confidence': confidence,
      'raw_text': rawText,
    };
  }
}
