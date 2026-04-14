import 'package:flutter/material.dart';

class VoucherHelpers {
  /// Format number with commas (e.g., 1000000 -> 1,000,000)
  static String formatWithCommas(int value) {
    final pattern = RegExp(r'(\d)(?=(\d{3})+$)');
    return value.toString().replaceAll(pattern, r'$1,');
  }

  /// Get icon for voucher category
  static Icon getCategoryIcon(String? category) {
    switch (category?.toLowerCase() ?? '') {
      case 'food':
        return Icon(Icons.restaurant, size: 24, color: Colors.orange);
      case 'shopping':
        return Icon(Icons.shopping_bag, size: 24, color: Colors.blue);
      case 'transportation':
        return Icon(Icons.directions_bus, size: 24, color: Colors.purple);
      case 'lifestyle':
        return Icon(Icons.spa, size: 24, color: Colors.pink);
      case 'exchange':
        return Icon(Icons.attach_money, size: 24, color: Colors.green);
      default:
        return Icon(Icons.card_giftcard, size: 24, color: Colors.grey);
    }
  }

  /// Get color for category badge background
  static Color getCategoryColor(String? category) {
    switch (category?.toLowerCase() ?? '') {
      case 'food':
        return Colors.orange.withOpacity(0.1);
      case 'shopping':
        return Colors.blue.withOpacity(0.1);
      case 'transportation':
        return Colors.purple.withOpacity(0.1);
      case 'lifestyle':
        return Colors.pink.withOpacity(0.1);
      case 'exchange':
        return Colors.green.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }
}
