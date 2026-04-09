import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseURL = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';
const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nY3J2dXpieHp3aW5uem1jd3hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4Njc3NzgsImV4cCI6MjA4ODQ0Mzc3OH0.uyJm3x5VgRVQ0YFjMExEw8r9cB-r7rIp2MHZcUkw4ZI';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static Future<void> initialize() async{
    try {
      await Supabase.initialize(
        url: _supabaseURL,
        anonKey: _supabaseKey,
      );
      print('DEBUG: Supabase initialized successfully');
    } catch (e) {
      print('DEBUG: Supabase initialization failed: $e');
    }
  }
//Redeemed vouchers
  static const String _redeemedVouchersTable = 'redeemed_vouchers';

  Future<List<Map<String, dynamic>>> fetchRedeemedVouchers({
    String? user_id,
    int? voucher_id,
    String? voucher_code,
  }) async {
    try {
      var query = client.from(_redeemedVouchersTable).select();
      if (user_id != null) query = query.eq('user_id', user_id);
      if (voucher_id != null) query = query.eq('voucher_id', voucher_id);
      if (voucher_code != null) query = query.eq('voucher_code', voucher_code);

      final data = await query;
      if (data is List) {
        return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch redeemed vouchers: ${e.message}');
    }
  }

  Future<void> insertRedeemedVoucher(Map<String, dynamic> redeemedVoucher) async {
    try {
      await client.from(_redeemedVouchersTable).insert(redeemedVoucher);
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert redeemed voucher: ${e.message}');
    }
  }

  Future<void> updateRedeemedVoucherByCode(
      String voucherCode,
      Map<String, dynamic> redeemedVoucher,
      ) async {
    try {
      await client
          .from(_redeemedVouchersTable)
          .update(redeemedVoucher)
          .eq('voucher_code', voucherCode);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update redeemed voucher $voucherCode: ${e.message}');
    }
  }

  Future<void> deleteRedeemedVoucherByCode(String voucherCode) async {
    try {
      await client.from(_redeemedVouchersTable).delete().eq('voucher_code', voucherCode);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete redeemed voucher $voucherCode: ${e.message}');
    }
  }

//Vouchers

  Future<List<Map<String, dynamic>>> fetchVouchers() async {
    try {
      final data = await client.from('vouchers').select();
      if (data is List) {
        return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch vouchers: ${e.message}');
    }
  }

  Future<void> insertVoucher(Map<String, dynamic> voucher) async {
    try {
      await client.from('vouchers').insert(voucher);
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert voucher: ${e.message}');
    }
  }

  Future<void> updateVoucher(int voucher_id, Map<String, dynamic> voucher) async {
    try {
      await client.from('vouchers').update(voucher).eq('voucher_id', voucher_id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update voucher $voucher_id: ${e.message}');
    }
  }

  Future<void> deleteVoucher(int voucher_id) async {
    try {
      await client.from('vouchers').delete().eq('voucher_id', voucher_id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete voucher $voucher_id: ${e.message}');
    }
  }
  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchVouchers() async {
    try {
      final data = await client.from('vouchers').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to fetch vouchers: $e');
    }
  }

  static const String _redeemedVouchersTable = 'redeemed_vouchers';

  Future<List<Map<String, dynamic>>> fetchRedeemedVouchers({
    String? user_id,
    String? voucher_id,
    String? voucher_code,
  }) async {
    try {
      var query = client.from(_redeemedVouchersTable).select();
      if (user_id != null) query = query.eq('user_id', user_id);
      if (voucher_id != null) query = query.eq('voucher_id', voucher_id);
      if (voucher_code != null) query = query.eq('voucher_code', voucher_code);

      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to fetch redeemed vouchers: $e');
    }
  }

  Future<void> insertRedeemedVoucher(Map<String, dynamic> redeemedVoucher) async {
    try {
      await client.from(_redeemedVouchersTable).insert(redeemedVoucher);
    } catch (e) {
      throw Exception('Failed to insert redeemed voucher: $e');
    }
  }

  Future<void> updateRedeemedVoucherByCode(
    String voucherCode,
    Map<String, dynamic> redeemedVoucher,
  ) async {
    try {
      await client
          .from(_redeemedVouchersTable)
          .update(redeemedVoucher)
          .eq('voucher_code', voucherCode);
    } catch (e) {
      throw Exception('Failed to update redeemed voucher $voucherCode: $e');
    }
  }

  Future<void> deleteRedeemedVoucherByCode(String voucherCode) async {
    try {
      await client.from(_redeemedVouchersTable).delete().eq('voucher_code', voucherCode);
    } catch (e) {
      throw Exception('Failed to delete redeemed voucher $voucherCode: $e');
    }
  }

  Future<void> insertVoucher(Map<String, dynamic> voucher) async {
    try {
      await client.from('vouchers').insert(voucher);
    } catch (e) {
      throw Exception('Failed to insert voucher: $e');
    }
  }

  Future<void> updateVoucher(String voucher_id, Map<String, dynamic> voucher) async {
    try {
      await client.from('vouchers').update(voucher).eq('voucher_id', voucher_id);
    } catch (e) {
      throw Exception('Failed to update voucher $voucher_id: $e');
    }
  }

  Future<void> deleteVoucher(String voucher_id) async {
    try {
      await client.from('vouchers').delete().eq('voucher_id', voucher_id);
    } catch (e) {
      throw Exception('Failed to delete voucher $voucher_id: $e');
    }
  }
}
