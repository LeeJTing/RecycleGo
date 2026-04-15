import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';
import 'package:recycle_go/view/voucher/helpers/voucher_bank_info_dialog.dart';
import 'package:recycle_go/view/voucher/helpers/voucher_status_helpers.dart';
import 'package:recycle_go/view/voucher/helpers/voucher_details_widgets.dart';

class VoucherUseConfirmationScreen extends StatefulWidget {
  final String voucherCode;
  final VoidCallback? onSuccess;

  const VoucherUseConfirmationScreen({
    super.key,
    required this.voucherCode,
    this.onSuccess,
  });

  @override
  State<VoucherUseConfirmationScreen> createState() =>
      _VoucherUseConfirmationScreenState();
}

class _VoucherUseConfirmationScreenState
    extends State<VoucherUseConfirmationScreen> {
  final RedeemVoucherCtrl _redeemCtrl = RedeemVoucherCtrl();
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  bool _isLoading = false;
  RedeemedVouchers? _redeemedVoucher;
  Vouchers? _voucherDetails;
  Users? _userDetails;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _loadVoucherDetails();
  }

  Future<void> _loadVoucherDetails() async {
    setState(() => _isLoading = true);
    try {
      await _redeemCtrl.fetchRedeemedVouchers(voucherCode: widget.voucherCode);

      if (_redeemCtrl.redeemedVouchers.isNotEmpty) {
        final redeemedVoucher = _redeemCtrl.redeemedVouchers[0];

        // Fetch voucher details
        await _voucherCtrl.fetchVouchers();
        final voucherDetails = _voucherCtrl.vouchers.firstWhere(
          (v) => v.voucherId == redeemedVoucher.voucherId,
          orElse: () => Vouchers(
            voucherName: 'Unknown',
            description: 'N/A',
            pointsRequired: 0,
            voucherStatus: 'inactive',
            voucherCategory: 'unknown',
            numberOfVouchers: 0,
          ),
        );

        // Fetch current user details
        final userProvider = context.read<UserProvider>();
        final currentUser = userProvider.user;

        setState(() {
          _redeemedVoucher = redeemedVoucher;
          _voucherDetails = voucherDetails;
          _userDetails = currentUser;
          _found = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _found = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading voucher: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUseVoucher() async {
    if (_redeemedVoucher == null) return;

    // Check if voucher is exchange type and validate/get bank information
    final isExchange = VoucherStatusHelpers.isExchangeVoucher(
      _voucherDetails?.voucherCategory,
    );

    String? bankName = _redeemedVoucher?.bankName;
    String? bankAccountNumber = _redeemedVoucher?.bankAccountNumber;

    if (isExchange) {
      // For exchange vouchers, ask for/update bank info
      final bankInfo = await VoucherBankInfoDialog.show(
        context,
        currentVoucher: _redeemedVoucher,
      );
      if (bankInfo == null) {
        // User cancelled
        return;
      }
      bankName = bankInfo['bankName'];
      bankAccountNumber = bankInfo['accountNumber'];

      // Get bank code for Stripe (internal use only)
      final bankCode = bankInfo['bankCode'];
    }

    setState(() => _isLoading = true);
    try {
      // For exchange vouchers, set status to pending (waiting for admin approval)
      // For other vouchers, set status to used immediately
      final newStatus = isExchange
          ? RedeemedVoucherStatus.pending
          : RedeemedVoucherStatus.used;

      // Update the voucher status (and bank info if provided)
      await _redeemCtrl.updateRedeemedVoucherStatus(
        _redeemedVoucher!.voucherCode,
        newStatus,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
      );

      if (mounted) {
        final theme = AppThemes.color;
        final message = VoucherStatusHelpers.getExchangeMessage(isExchange);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: theme.primary),
        );
        // Small delay to ensure database update is committed
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to use voucher: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Use Voucher', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : !_found
          ? const VoucherNotFoundWidget()
          : _buildVoucherConfirmationScreen(),
    );
  }

  Widget _buildVoucherConfirmationScreen() {
    if (_redeemedVoucher == null) return const SizedBox.shrink();

    final isAlreadyUsed =
        _redeemedVoucher!.voucherStatus == RedeemedVoucherStatus.used;
    final isExchange = VoucherStatusHelpers.isExchangeVoucher(
      _voucherDetails?.voucherCategory,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code
            Center(
              child: QRCodeHelpers.buildQRCode(_redeemedVoucher!.voucherCode),
            ),
            const SizedBox(height: 24),

            // Voucher Status
            VoucherStatusBadge(status: _redeemedVoucher!.voucherStatus),
            const SizedBox(height: 16),

            // Details
            VoucherDetailsWidget(voucher: _redeemedVoucher!),
            const SizedBox(height: 16),

            // Bank Information (only for exchange vouchers)
            BankTransferDetailWidget(
              voucher: _redeemedVoucher!,
              voucherDetails: _voucherDetails,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            VoucherActionButtonsWidget(
              isAlreadyUsed: isAlreadyUsed,
              onUseVoucher: _confirmUseVoucher,
            ),
          ],
        ),
      ),
    );
  }
}
