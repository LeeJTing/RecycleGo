import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// entity
class Vouchers {
  final String? voucherId;
  final String voucherName;
  final String description;
  final int pointsRequired;
  final String voucherStatus;
  final String voucherCategory;
  final int numberOfVouchers;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isInfinite;
  final int? voucherDuration;

  Vouchers({
    this.voucherId,
    required this.voucherName,
    required this.description,
    required this.pointsRequired,
    required this.voucherStatus,
    required this.voucherCategory,
    required this.numberOfVouchers,
    this.createdAt,
    this.updatedAt,
    this.isInfinite = false,
    this.voucherDuration,
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

  factory Vouchers.fromJson(Map<String, dynamic> data) {
    return Vouchers(
      voucherId: data['voucher_id'] != null
          ? data['voucher_id'].toString()
          : null,
      voucherName: (data['voucher_name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      pointsRequired: _asInt(data['points_required']),
      voucherStatus: (data['voucher_status'] ?? '').toString(),
      voucherCategory: (data['voucher_category'] ?? '').toString(),
      numberOfVouchers: _asInt(data['number_of_vouchers']),
      createdAt: _asDateTime(data['created_at']),
      updatedAt: _asDateTime(data['updated_at']),
      isInfinite: data['is_infinite'] == true || data['is_infinite'] == 1,
      voucherDuration: _asInt(data['voucher_duration'], defaultValue: 0) == 0
          ? null
          : _asInt(data['voucher_duration']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucher_id': voucherId,
      'voucher_name': voucherName,
      'description': description,
      'points_required': pointsRequired,
      'voucher_status': voucherStatus,
      'voucher_category': voucherCategory,
      'number_of_vouchers': numberOfVouchers,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_infinite': isInfinite,
      'voucher_duration': voucherDuration,
    };
  }
}

class VouchersModel extends Connector {
  Future<List<Vouchers>> fetchVouchers() async {
    try {
      final response = await Supabase.instance.client.from('vouchers').select();
      return (response as List)
          .map((e) => Vouchers.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch vouchers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch vouchers: $e');
    }
  }

  Future<void> insertVouchers(Vouchers vouchers) async {
    try {
      await Supabase.instance.client.from('vouchers').insert(vouchers.toJson());
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to insert voucher: $e');
    }
  }

  Future<void> updateVouchers(String id, Vouchers vouchers) async {
    try {
      await Supabase.instance.client
          .from('vouchers')
          .update(vouchers.toJson())
          .eq('voucher_id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update voucher: $e');
    }
  }

  Future<void> deleteVouchers(String id) async {
    try {
      await Supabase.instance.client
          .from('vouchers')
          .delete()
          .eq('voucher_id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete voucher: $e');
    }
  }
}
