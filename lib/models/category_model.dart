import 'package:flutter/material.dart';

class ExpenseCategory {
  static const String food = 'Food';
  static const String travel = 'Travel';
  static const String shopping = 'Shopping';
  static const String bills = 'Bills';
  static const String entertainment = 'Entertainment';
  static const String other = 'Other';

  static List<String> get all => [food, travel, shopping, bills, entertainment, other];
  static List<String> get allCategories => [food, travel, shopping, bills, entertainment, other];

  static IconData getIcon(String category) {
    switch (category) {
      case food:
        return Icons.restaurant;
      case travel:
        return Icons.flight;
      case shopping:
        return Icons.shopping_bag;
      case bills:
        return Icons.receipt_long;
      case entertainment:
        return Icons.movie;
      case other:
      default:
        return Icons.category;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case food:
        return Colors.orange;
      case travel:
        return Colors.blue;
      case shopping:
        return Colors.purple;
      case bills:
        return Colors.red;
      case entertainment:
        return Colors.pink;
      case other:
      default:
        return Colors.grey;
    }
  }
}
