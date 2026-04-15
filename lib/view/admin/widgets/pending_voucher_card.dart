import 'package:flutter/material.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/services/stripe_dev_service.dart';

class PendingVoucherCard extends StatefulWidget {
  final RedeemedVouchers pendingVoucher;
  final AppColors theme;
  final VoidCallback? onProcessed;

  const PendingVoucherCard({
    super.key,
    required this.pendingVoucher,
    required this.theme,
    this.onProcessed,
  });

  @override
  State<PendingVoucherCard> createState() => _PendingVoucherCardState();
}

class _PendingVoucherCardState extends State<PendingVoucherCard> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  final StripeDevService _stripeDevService = StripeDevService();
  final RedeemedVouchersModel _redeemedVouchersModel = RedeemedVouchersModel();
  Vouchers? _voucherDetails;
  bool _isVoucherLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadVoucherDetails();
  }

  Future<void> _loadVoucherDetails() async {
    try {
      await _voucherCtrl.fetchVouchers();
      final voucher = _voucherCtrl.vouchers.firstWhere(
        (v) => v.voucherId == widget.pendingVoucher.voucherId,
        orElse: () => Vouchers(
          voucherName: 'Unknown',
          description: 'N/A',
          pointsRequired: 0,
          voucherStatus: 'inactive',
          voucherCategory: 'unknown',
          numberOfVouchers: 0,
        ),
      );

      if (mounted) {
        setState(() {
          _voucherDetails = voucher;
          _isVoucherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVoucherLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.pendingVoucher.voucherCode,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'User ID: ${widget.pendingVoucher.userId}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.theme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (_isVoucherLoading)
              Text(
                'Loading description...',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.theme.hint,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                'Voucher: ${_voucherDetails?.description ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: widget.theme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            if (widget.pendingVoucher.bankName != null) ...[
              Text(
                'Bank: ${widget.pendingVoucher.bankName}',
                style: TextStyle(fontSize: 12, color: widget.theme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Account: ${_maskAccountNumber(widget.pendingVoucher.bankAccountNumber)}',
                style: TextStyle(fontSize: 12, color: widget.theme.onSurface),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isVoucherLoading || _isProcessing)
                    ? null
                    : _openStripePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Process with Stripe',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStripePayment() async {
    final bankName = widget.pendingVoucher.bankName ?? '';
    final accountNumber = widget.pendingVoucher.bankAccountNumber ?? '';

    if (bankName.isEmpty || accountNumber.isEmpty) {
      _showErrorSnackBar('Missing bank details for this pending voucher');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _stripeDevService.processPayout(
        voucherCode: widget.pendingVoucher.voucherCode,
        userId: widget.pendingVoucher.userId,
        bankName: bankName,
        bankAccountNumber: accountNumber,
      );

      final updatedVoucher = RedeemedVouchers(
        voucherCode: widget.pendingVoucher.voucherCode,
        userId: widget.pendingVoucher.userId,
        voucherId: widget.pendingVoucher.voucherId,
        voucherStatus: RedeemedVoucherStatus.used,
        redeemedAt: widget.pendingVoucher.redeemedAt,
        bankName: widget.pendingVoucher.bankName,
        bankAccountNumber: widget.pendingVoucher.bankAccountNumber,
      );

      await _redeemedVouchersModel.updateRedeemedVoucherByCode(
        widget.pendingVoucher.voucherCode,
        updatedVoucher,
      );

      _showSuccessSnackBar('Stripe payout sent in development mode');
      widget.onProcessed?.call();
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: widget.theme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return 'N/A';
    if (accountNumber.length <= 4) return accountNumber;
    return '**** ${accountNumber.substring(accountNumber.length - 4)}';
  }
}
