import 'package:flutter/material.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';

/// Helper class for voucher status-related UI utilities
class VoucherStatusHelpers {
  /// Get color for a specific voucher status
  static Color getStatusColor(RedeemedVoucherStatus status) {
    switch (status) {
      case RedeemedVoucherStatus.pending:
        return Colors.amber;
      case RedeemedVoucherStatus.unused:
        return Colors.blue;
      case RedeemedVoucherStatus.used:
        return Colors.green;
      case RedeemedVoucherStatus.shared:
        return Colors.purple;
    }
  }

  /// Get background color for a specific voucher status (with opacity)
  static Color getStatusBackgroundColor(RedeemedVoucherStatus status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  /// Mask account number for display (show only last 4 digits)
  static String maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final last4 = accountNumber.substring(accountNumber.length - 4);
    final masked = '*' * (accountNumber.length - 4);
    return '$masked$last4';
  }

  /// Check if voucher is exchange type
  static bool isExchangeVoucher(String? category) {
    final normalized = category?.toLowerCase().trim() ?? '';
    return normalized == 'exchange' || normalized.contains('exchange');
  }

  /// Get status message for exchange vouchers
  static String getExchangeMessage(bool isExchange) {
    return isExchange
        ? 'Voucher submitted! Awaiting admin approval for bank transfer.'
        : 'Voucher successfully used!';
  }
}
