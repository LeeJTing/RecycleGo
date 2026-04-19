import 'package:flutter/cupertino.dart';
import 'package:recycle_go/models/Vouchers.dart';

class VoucherCtrl {
  static final VoucherCtrl _instance = VoucherCtrl._internal();

  VoucherCtrl._internal();

  factory VoucherCtrl() => _instance;

  final VouchersModel _vouchersModel = VouchersModel();
  List<Vouchers> vouchers = [];

  // Fetch vouchers from Supabase
  Future<void> fetchVouchers() async {
    try {
      vouchers = await _vouchersModel.fetchVouchers();
    } catch (e) {
      throw Exception('Failed to fetch vouchers: $e');
    }
  }

  // Add new voucher to Supabase
  Future<void> addVoucher(Vouchers voucher) async {
    try {
      await _vouchersModel.insertVouchers(voucher);
      vouchers.add(voucher);
    } catch (e) {
      throw Exception('Failed to add voucher: $e');
    }
  }

  // Update voucher in Supabase
  Future<void> updateVoucher(String voucherId, Vouchers voucher) async {
    try {
      await _vouchersModel.updateVouchers(voucherId, voucher);
      final index = vouchers.indexWhere((v) => v.voucherId == voucherId);
      if (index >= 0) {
        vouchers[index] = voucher;
      }
    } catch (e) {
      throw Exception('Failed to update voucher: $e');
    }
  }

  // Toggle voucher status and sync to Supabase
  Future<void> toggleVoucherStatus(String voucherId) async {
    try {
      final index = vouchers.indexWhere((v) => v.voucherId == voucherId);
      if (index >= 0) {
        final voucher = vouchers[index];
        final newStatus = voucher.voucherStatus == 'active'
            ? 'inactive'
            : 'active';
        final updatedVoucher = Vouchers(
          voucherId: voucher.voucherId,
          voucherName: voucher.voucherName,
          description: voucher.description,
          pointsRequired: voucher.pointsRequired,
          voucherStatus: newStatus,
          voucherCategory: voucher.voucherCategory,
          numberOfVouchers: voucher.numberOfVouchers,
          createdAt: voucher.createdAt,
          updatedAt: DateTime.now(),
          voucherDuration: voucher.voucherDuration,
          isInfinite: voucher.isInfinite,
        );
        // Update in Supabase
        await _vouchersModel.updateVouchers(voucherId, updatedVoucher);
        // Update local list
        vouchers[index] = updatedVoucher;
      }
    } catch (e) {
      throw Exception('Failed to toggle voucher status: $e');
    }
  }

  // Delete voucher from Supabase
  Future<void> deleteVoucher(String voucherId) async {
    try {
      await _vouchersModel.deleteVouchers(voucherId);
      vouchers.removeWhere((v) => v.voucherId == voucherId);
    } catch (e) {
      throw Exception('Failed to delete voucher: $e');
    }
  }

  // Auto-inactivate expired vouchers
  Future<List<String>> autoInactivateExpiredVouchers() async {
    try {
      final inactivatedIds = await _vouchersModel
          .autoInactivateExpiredVouchers();
      // Refresh local list after inactivation
      await fetchVouchers();
      return inactivatedIds;
    } catch (e) {
      throw Exception('Failed to auto-inactivate vouchers: $e');
    }
  }
}
