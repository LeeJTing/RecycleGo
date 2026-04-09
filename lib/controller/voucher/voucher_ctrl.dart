import 'package:flutter/cupertino.dart';
import 'package:recycle_go/models/Vouchers.dart';

class VoucherCtrl {
  static final VoucherCtrl _instance = VoucherCtrl._internal();

  VoucherCtrl._internal();

  factory VoucherCtrl() => _instance;

  // Sample voucher data - replace with API calls later
  List<Vouchers> vouchers = [
    Vouchers(
      voucherId: '1',
      voucherName: 'Voucher 1',
      description: 'Discount 5%',
      pointsRequired: 800,
      voucherStatus: 'active',
      voucherCategory: 'Food',
      numberOfVoucher: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isInfinite: true,
    ),
    Vouchers(
      voucherId: '2',
      voucherName: 'Voucher 2',
      description: 'Discount 10%',
      pointsRequired: 500,
      voucherStatus: 'active',
      voucherCategory: 'Shopping',
      numberOfVoucher: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isInfinite: false,
      voucherDuration: 7,
    ),
    Vouchers(
      voucherId: '3',
      voucherName: 'Voucher 3',
      description: 'Free Drink',
      pointsRequired: 300,
      voucherStatus: 'inactive',
      voucherCategory: 'Food',
      numberOfVoucher: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isInfinite: false,
      voucherDuration: 30,
    ),
  ];

  // Add new voucher
  void addVoucher(Vouchers voucher) {
    vouchers.add(voucher);
  }

  // Update voucher
  void updateVoucher(int index, Vouchers voucher) {
    if (index >= 0 && index < vouchers.length) {
      vouchers[index] = voucher;
    }
  }

  // Toggle voucher status
  void toggleVoucherStatus(int index) {
    if (index >= 0 && index < vouchers.length) {
      final voucher = vouchers[index];
      final newStatus = voucher.voucherStatus == 'active'
          ? 'inactive'
          : 'active';
      vouchers[index] = Vouchers(
        voucherId: voucher.voucherId,
        voucherName: voucher.voucherName,
        description: voucher.description,
        pointsRequired: voucher.pointsRequired,
        voucherStatus: newStatus,
        voucherCategory: voucher.voucherCategory,
        numberOfVoucher: voucher.numberOfVoucher,
        createdAt: voucher.createdAt,
        updatedAt: DateTime.now(),
        voucherDuration: voucher.voucherDuration,
        isInfinite: voucher.isInfinite,
      );
    }
  }

  // Delete voucher
  void deleteVoucher(int index) {
    if (index >= 0 && index < vouchers.length) {
      vouchers.removeAt(index);
    }
  }
}
