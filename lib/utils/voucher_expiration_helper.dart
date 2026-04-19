import 'package:recycle_go/models/Vouchers.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Helper class for voucher expiration-related utilities
class VoucherExpirationHelper {
  /// Check if a voucher has expired
  static bool isExpired(Vouchers voucher) {
    return voucher.isExpired();
  }

  /// Get expiration date for a voucher
  static DateTime? getExpirationDate(Vouchers voucher) {
    return voucher.getExpirationDate();
  }

  /// Get days remaining until expiration
  static int? getDaysRemaining(Vouchers voucher) {
    return voucher.daysUntilExpiration();
  }

  /// Get expiration status text
  /// Returns formatted string like "Expires in 5 days" or "Expired"
  static String getExpirationStatus(Vouchers voucher) {
    if (voucher.isInfinite) {
      return 'Expires: Never';
    }

    final daysRemaining = voucher.daysUntilExpiration();
    if (daysRemaining == null) {
      return 'Expiration unknown';
    }

    if (daysRemaining <= 0) {
      return 'Expired';
    } else if (daysRemaining == 1) {
      return 'Expires tomorrow';
    } else if (daysRemaining <= 7) {
      return 'Expires in $daysRemaining days';
    } else {
      final expiryDate = voucher.getExpirationDate();
      if (expiryDate != null) {
        final formatted = DateFormat('MMM d, yyyy').format(expiryDate);
        return 'Expires on $formatted';
      }
      return 'Expires in $daysRemaining days';
    }
  }

  /// Get color based on expiration status
  /// Red if expired, Orange if expiring soon (<=7 days), Green if plenty of time
  static Color? getExpirationColor(Vouchers voucher) {
    if (voucher.isInfinite) return null;

    final daysRemaining = voucher.daysUntilExpiration();
    if (daysRemaining == null) return null;

    if (daysRemaining <= 0) return const Color(0xFFE53935); // Red
    if (daysRemaining <= 7) return const Color(0xFFFB8C00); // Orange
    return const Color(0xFF43A047); // Green
  }
}
