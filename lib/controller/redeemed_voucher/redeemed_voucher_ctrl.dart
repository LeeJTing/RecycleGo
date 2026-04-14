import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/models/Vouchers.dart';

class RedeemVoucherCtrl {
  static final RedeemVoucherCtrl _instance = RedeemVoucherCtrl._internal();

  RedeemVoucherCtrl._internal();

  factory RedeemVoucherCtrl() => _instance;

  final RedeemedVouchersModel _redeemedVouchersModel = RedeemedVouchersModel();
  List<RedeemedVouchers> redeemedVouchers = [];

  // Fetch all redeemed vouchers
  Future<void> fetchRedeemedVouchers({
    String? userId,
    String? voucherId,
    String? voucherCode,
  }) async {
    try {
      redeemedVouchers = await _redeemedVouchersModel.fetchRedeemedVouchers(
        userId: userId,
        voucherId: voucherId,
        voucherCode: voucherCode,
      );
    } catch (e) {
      throw Exception('Failed to fetch redeemed vouchers: $e');
    }
  }

  // Fetch redeemed vouchers by user
  Future<void> fetchRedeemedVouchersByUser(String userId) async {
    try {
      redeemedVouchers = await _redeemedVouchersModel.fetchRedeemedVouchers(
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to fetch user redeemed vouchers: $e');
    }
  }

  // Add new redeemed voucher
  Future<void> addRedeemedVoucher(RedeemedVouchers redeemedVoucher) async {
    try {
      await _redeemedVouchersModel.insertRedeemedVoucher(redeemedVoucher);
      redeemedVouchers.add(redeemedVoucher);
    } catch (e) {
      throw Exception('Failed to add redeemed voucher: $e');
    }
  }

  // Update redeemed voucher status
  Future<void> updateRedeemedVoucherStatus(
    String voucherCode,
    RedeemedVoucherStatus newStatus, {
    String? bankName,
    String? bankAccountNumber,
  }) async {
    try {
      final index = redeemedVouchers.indexWhere(
        (v) => v.voucherCode == voucherCode,
      );
      if (index >= 0) {
        final voucher = redeemedVouchers[index];
        final updatedVoucher = RedeemedVouchers(
          voucherCode: voucher.voucherCode,
          userId: voucher.userId,
          voucherId: voucher.voucherId,
          voucherStatus: newStatus,
          redeemedAt: voucher.redeemedAt,
          bankName: bankName ?? voucher.bankName,
          bankAccountNumber: bankAccountNumber ?? voucher.bankAccountNumber,
        );
        await _redeemedVouchersModel.updateRedeemedVoucherByCode(
          voucherCode,
          updatedVoucher,
        );
        redeemedVouchers[index] = updatedVoucher;
      }
    } catch (e) {
      throw Exception('Failed to update redeemed voucher status: $e');
    }
  }

  // Delete redeemed voucher
  Future<void> deleteRedeemedVoucher(String voucherCode) async {
    try {
      await _redeemedVouchersModel.deleteRedeemedVoucherByCode(voucherCode);
      redeemedVouchers.removeWhere((v) => v.voucherCode == voucherCode);
    } catch (e) {
      throw Exception('Failed to delete redeemed voucher: $e');
    }
  }

  // Get count by status
  int getCountByStatus(RedeemedVoucherStatus status) {
    return redeemedVouchers.where((v) => v.voucherStatus == status).length;
  }

  // Get vouchers by status
  List<RedeemedVouchers> getVouchersByStatus(RedeemedVoucherStatus status) {
    return redeemedVouchers.where((v) => v.voucherStatus == status).toList();
  }

  // Generate next sequential voucher code globally (unique across all vouchers)
  Future<String> generateNextVoucherCode(String voucherId) async {
    try {
      // Fetch ALL redeemed vouchers (to find globally highest sequence)
      await fetchRedeemedVouchers();

      // Base prefix for voucher codes
      const basePrefix = '44444444-4444-4444-4444-';

      // Find the highest existing sequence number globally
      int maxSequence = 0;

      for (var voucher in redeemedVouchers) {
        // Extract the last 12 digits (sequence number)
        final code = voucher.voucherCode;
        if (code.startsWith(basePrefix)) {
          final sequencePart = code.substring(basePrefix.length);
          final sequence = int.tryParse(sequencePart) ?? 0;
          if (sequence > maxSequence) {
            maxSequence = sequence;
          }
        }
      }

      // Generate next code with incremented sequence
      final nextSequence = maxSequence + 1;
      final sequenceStr = nextSequence.toString().padLeft(12, '0');
      final generatedCode = '$basePrefix$sequenceStr';
      return generatedCode;
    } catch (e) {
      throw Exception('Failed to generate voucher code: $e');
    }
  }

  // Redeem voucher with points deduction and transaction handling
  Future<String> redeemVoucherWithTransaction({
    required Users user,
    required Vouchers voucher,
    required String userId,
    required String voucherId,
  }) async {
    final UsersModel usersModel = UsersModel();
    String? voucherCode;

    try {
      if (user.totalPoints < voucher.pointsRequired) {
        throw Exception('Insufficient points');
      }
      final deductedPoints = user.totalPoints - voucher.pointsRequired;
      final updatedUser = user.copyWith(totalPoints: deductedPoints);

      await usersModel.updateUser(updatedUser);

      try {
        voucherCode = await generateNextVoucherCode(voucherId);

        // Step 5: Create redeemed voucher with 'unused' status
        final redeemedVoucher = RedeemedVouchers(
          voucherCode: voucherCode,
          userId: userId,
          voucherId: voucherId,
          voucherStatus: RedeemedVoucherStatus.unused,
          redeemedAt: DateTime.now(),
        );

        await addRedeemedVoucher(redeemedVoucher);
        return voucherCode;
      } catch (e) {
        await usersModel.updateUser(user);
        throw Exception('Failed to generate voucher code, points restored: $e');
      }
    } catch (e) {
      throw Exception('Voucher redemption failed: $e');
    }
  }
}
