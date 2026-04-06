import 'package:recycle_go/models/Connector.dart';

class Vouchers {
  final String? voucherId;
  final String voucherName;
  final String? description;
  final int pointsRequired;
  final String voucherStatus;
  final String voucherCategory;
  final int numberOfVoucher;
  final DateTime? createdAt;

  Vouchers({
    this.voucherId,
    required this.voucherName,
    this.description,
    required this.pointsRequired,
    required this.voucherStatus,
    required this.voucherCategory,
    required this.numberOfVoucher,
    this.createdAt,
  });

  factory Vouchers.fromJson(Map<String, dynamic> json) {
    return Vouchers(
      voucherId: json['voucher_id'],
      voucherName: json['voucher_name'],
      description: json['description'],
      pointsRequired: json['points_required'],
      voucherStatus: json['voucher_status'],
      voucherCategory: json['voucher_category'],
      numberOfVoucher: json['number_of_voucher'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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
      'number_of_voucher': numberOfVoucher,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class VouchersModel extends Connector {}
