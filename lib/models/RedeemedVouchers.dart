import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// entity
enum RedeemedVoucherStatus { unused, used, shared }

extension RedeemedVoucherStatusDb on RedeemedVoucherStatus {
  String get dbValue => switch (this) {
    RedeemedVoucherStatus.unused => 'unused',
    RedeemedVoucherStatus.used => 'used',
    RedeemedVoucherStatus.shared => 'shared',
  };

  static RedeemedVoucherStatus fromDbValue(dynamic value) {
    final normalized = (value ?? '').toString().toLowerCase().trim();
    switch (normalized) {
      case 'used':
        return RedeemedVoucherStatus.used;
      case 'shared':
        return RedeemedVoucherStatus.shared;
      case 'unused':
      default:
        return RedeemedVoucherStatus.unused;
    }
  }
}

class RedeemedVouchers {
  final String voucherCode;
  final String userId;
  final String voucherId;
  final RedeemedVoucherStatus voucherStatus;
  final DateTime? redeemedAt;

  RedeemedVouchers({
    required this.voucherCode,
    required this.userId,
    required this.voucherId,
    required this.voucherStatus,
    this.redeemedAt,
  });

  static int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  factory RedeemedVouchers.fromJson(Map<String, dynamic> data) {
    return RedeemedVouchers(
      voucherCode: (data['voucher_code'] ?? '').toString(),
      userId: (data['user_id'] ?? '').toString(),
      voucherId: (data['voucher_id'] ?? '').toString(),
      voucherStatus: RedeemedVoucherStatusDb.fromDbValue(
        data['voucher_status'],
      ),
      redeemedAt: _asDateTime(data['redeemed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucher_code': voucherCode,
      'user_id': userId,
      'voucher_id': voucherId,
      'voucher_status': voucherStatus.dbValue,
      'redeemed_at': redeemedAt?.toIso8601String(),
    };
  }
}

class RedeemedVouchersModel extends Connector {
  Future<List<RedeemedVouchers>> fetchRedeemedVouchers({
    String? userId,
    String? voucherId,
    String? voucherCode,
  }) async {
    try {
      var query = Supabase.instance.client.from('redeemed_vouchers').select();
      if (userId != null) query = query.eq('user_id', userId);
      if (voucherId != null) query = query.eq('voucher_id', voucherId);
      if (voucherCode != null) query = query.eq('voucher_code', voucherCode);

      final data = await query;
      return (data as List)
          .map((e) => RedeemedVouchers.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch redeemed vouchers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch redeemed vouchers: $e');
    }
  }

  Future<void> insertRedeemedVoucher(RedeemedVouchers redeemedVoucher) async {
    try {
      await Supabase.instance.client
          .from('redeemed_vouchers')
          .insert(redeemedVoucher.toJson());
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert redeemed voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to insert redeemed voucher: $e');
    }
  }

  Future<void> updateRedeemedVoucherByCode(
    String voucherCode,
    RedeemedVouchers redeemedVoucher,
  ) async {
    try {
      await Supabase.instance.client
          .from('redeemed_vouchers')
          .update(redeemedVoucher.toJson())
          .eq('voucher_code', voucherCode);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update redeemed voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update redeemed voucher: $e');
    }
  }

  Future<void> deleteRedeemedVoucherByCode(String voucherCode) async {
    try {
      await Supabase.instance.client
          .from('redeemed_vouchers')
          .delete()
          .eq('voucher_code', voucherCode);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete redeemed voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete redeemed voucher: $e');
    }
  }
}
