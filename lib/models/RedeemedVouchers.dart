import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/services/supabase_service.dart';

// entity
enum RedeemedVoucherStatus {
	unused,
	used,
	shared;
}

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
	final String voucher_code;
	final String user_id;
	final int voucher_id;
	final RedeemedVoucherStatus voucher_status;
	final DateTime? redeemed_at;

	RedeemedVouchers({
		required this.voucher_code,
		required this.user_id,
		required this.voucher_id,
		required this.voucher_status,
		this.redeemed_at,
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
			voucher_code: (data['voucher_code'] ?? '').toString(),
			user_id: (data['user_id'] ?? '').toString(),
			voucher_id: _asInt(data['voucher_id']),
			voucher_status: RedeemedVoucherStatusDb.fromDbValue(data['voucher_status']),
			redeemed_at: _asDateTime(data['redeemed_at']),
		);
	}

	Map<String, dynamic> toMap({bool includeRedeemedAt = false}) {
		final map = <String, dynamic>{
			'voucher_code': voucher_code,
			'user_id': user_id,
			'voucher_id': voucher_id,
			'voucher_status': voucher_status.dbValue,
		};

		if (includeRedeemedAt && redeemed_at != null) {
			map['redeemed_at'] = redeemed_at!.toIso8601String();
		}
		return map;
	}
}

class RedeemedVouchersModel extends Connector{
	final _supabaseService = SupabaseService();

	Future<List<RedeemedVouchers>> fetchRedeemedVouchers({
		String? user_id,
		String? voucher_id,
		String? voucher_code,
	}) async {
		final response = await _supabaseService.fetchRedeemedVouchers(
			user_id: user_id,
			voucher_id: voucher_id,
			voucher_code: voucher_code,
		);
		return response.map((e) => RedeemedVouchers.fromJson(e)).toList();
	}

	Future<void> insertRedeemedVoucher(RedeemedVouchers redeemedVoucher) async {
		await _supabaseService.insertRedeemedVoucher(redeemedVoucher.toMap());
	}

	Future<void> updateRedeemedVoucherByCode(
		String voucherCode,
		RedeemedVouchers redeemedVoucher,
	) async {
		await _supabaseService.updateRedeemedVoucherByCode(
			voucherCode,
			redeemedVoucher.toMap(includeRedeemedAt: true),
		);
	}

	Future<void> deleteRedeemedVoucherByCode(String voucherCode) async {
		await _supabaseService.deleteRedeemedVoucherByCode(voucherCode);
	}
}