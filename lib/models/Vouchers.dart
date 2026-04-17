import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/supabase_service.dart';

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

  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
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
      numberOfVouchers: _asInt(data['number_of_voucher']),
      createdAt: _asDateTime(data['created_at']),
      updatedAt: _asDateTime(data['updated_at']),
      isInfinite: _asBool(data['is_infinite']),
      voucherDuration: _asInt(data['voucher_duration'], defaultValue: 0) == 0
          ? null
          : _asInt(data['voucher_duration']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'voucher_name': voucherName,
      'description': description,
      'points_required': pointsRequired,
      'voucher_status': voucherStatus,
      'voucher_category': voucherCategory,
      'number_of_voucher': numberOfVouchers,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_infinite': isInfinite,
      'voucher_duration': voucherDuration,
    };

    if (voucherId != null) {
      map['voucher_id'] = voucherId;
    }

    return map;
  }
}

class VouchersModel extends Connector {
  // Generate next sequential voucher ID
  Future<String> _generateNextVoucherId() async {
    try {
      // Fetch all vouchers to find the highest sequence
      final response = await SupabaseService().client.from('vouchers').select();
      final vouchers = (response as List)
          .map((e) => Vouchers.fromJson(e as Map<String, dynamic>))
          .toList();

      if (vouchers.isEmpty) {
        // First voucher starts at 1
        return '55555555-5555-5555-5555-000000000001';
      }

      // Extract sequence numbers from existing IDs
      int maxSequence = 0;
      for (var voucher in vouchers) {
        if (voucher.voucherId != null) {
          // Extract last part: 55555555-5555-5555-5555-XXXXXXXXXXXX
          final parts = voucher.voucherId!.split('-');
          if (parts.length == 5) {
            final sequence = int.tryParse(parts[4]) ?? 0;
            if (sequence > maxSequence) {
              maxSequence = sequence;
            }
          }
        }
      }

      // Generate next ID
      final nextSequence = maxSequence + 1;
      final sequenceStr = nextSequence.toString().padLeft(12, '0');
      return '55555555-5555-5555-5555-$sequenceStr';
    } catch (e) {
      throw Exception('Failed to generate voucher ID: $e');
    }
  }

  Future<List<Vouchers>> fetchVouchers() async {
    try {
      final response = await SupabaseService().client.from('vouchers').select();
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
      // Generate sequential ID if not provided
      final voucherToInsert = vouchers.voucherId == null
          ? Vouchers(
              voucherId: await _generateNextVoucherId(),
              voucherName: vouchers.voucherName,
              description: vouchers.description,
              pointsRequired: vouchers.pointsRequired,
              voucherStatus: vouchers.voucherStatus,
              voucherCategory: vouchers.voucherCategory,
              numberOfVouchers: vouchers.numberOfVouchers,
              createdAt: vouchers.createdAt,
              updatedAt: vouchers.updatedAt,
              isInfinite: vouchers.isInfinite,
              voucherDuration: vouchers.voucherDuration,
            )
          : vouchers;

      await SupabaseService().client
          .from('vouchers')
          .insert(voucherToInsert.toJson());
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert voucher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to insert voucher: $e');
    }
  }

  Future<void> updateVouchers(String id, Vouchers vouchers) async {
    try {
      await SupabaseService().client
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
      await SupabaseService().client
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
