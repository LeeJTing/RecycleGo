import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/services/supabase_service.dart';

// entity
class Vouchers {
  final int? voucher_id;
  final String voucher_name;
  final String description;
  final int points_required;
  final String voucher_status;
  final String voucher_category;
  final int number_of_vouchers;
  final DateTime? created_at;

  Vouchers({
    this.voucher_id,
    required this.voucher_name,
    required this.description,
    required this.points_required,
    required this.voucher_status,
    required this.voucher_category,
    required this.number_of_vouchers,
    this.created_at,
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
      voucher_id: _asInt(data['voucher_id'], defaultValue: 0) == 0
          ? null
          : _asInt(data['voucher_id']),
      voucher_name: (data['voucher_name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      points_required: _asInt(data['points_required']),
      voucher_status: (data['voucher_status'] ?? '').toString(),
      voucher_category: (data['voucher_category'] ?? '').toString(),
      number_of_vouchers: _asInt(data['number_of_vouchers']),
      created_at: _asDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toMap({
    bool includeId = false,
    bool includeCreatedAt = false,
  }) {
    final map = <String, dynamic>{
      'voucher_name': voucher_name,
      'description': description,
      'points_required': points_required,
      'voucher_status': voucher_status,
      'voucher_category': voucher_category,
      'number_of_vouchers': number_of_vouchers,
    };

    if (includeId && voucher_id != null) {
      map['voucher_id'] = voucher_id;
    }
    if (includeCreatedAt && created_at != null) {
      map['created_at'] = created_at!.toIso8601String();
    }

    return map;
  }
}

class VouchersModel extends Connector {
  final _supabaseService = SupabaseService();

  Future<List<Vouchers>> fetchVouchers() async {
    final response = await _supabaseService.fetchVouchers();
    return response.map((e) => Vouchers.fromJson(e)).toList();
  }

  Future<void> insertVouchers(Vouchers vouchers) async {
    await _supabaseService.insertVoucher(vouchers.toMap());
  }

  Future<void> updateVouchers(int id, Vouchers vouchers) async {
    await _supabaseService.updateVoucher(id, vouchers.toMap());
  }

  Future<void> deleteVouchers(int id) async {
    await _supabaseService.deleteVoucher(id);
  }
}
