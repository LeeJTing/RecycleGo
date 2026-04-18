import 'package:flutter/material.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/services/supabase_service.dart';

class PendingVoucherCard extends StatefulWidget {
  final RedeemedVouchers pendingVoucher;
  final AppColors theme;
  final Future<void> Function()? onProcessed;

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
                  softWrap: true,
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
              'Account: ${_fullAccountNumber(widget.pendingVoucher.bankAccountNumber)}',
              style: TextStyle(fontSize: 12, color: widget.theme.onSurface),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_isVoucherLoading || _isProcessing)
                        ? null
                        : _markTransferAsCompleted,
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
                            'Mark Transfer Done',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: (_isVoucherLoading || _isProcessing)
                        ? null
                        : _payViaStripeTest,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.theme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payment,
                          size: 14,
                          color: widget.theme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Stripe',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: widget.theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markTransferAsCompleted() async {
    final bankName = widget.pendingVoucher.bankName ?? '';
    final accountNumber = widget.pendingVoucher.bankAccountNumber ?? '';

    if (bankName.isEmpty || accountNumber.isEmpty) {
      _showErrorSnackBar('Missing bank details for this pending voucher');
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (confirmed != true) {
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
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

      if (widget.onProcessed != null && mounted) {
        await widget.onProcessed!.call();
      }

      _showSuccessSnackBar('Voucher marked as paid via bank transfer.');
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _payViaStripeTest() async {
    final bankName = widget.pendingVoucher.bankName ?? '';
    final accountNumber = widget.pendingVoucher.bankAccountNumber ?? '';

    if (bankName.isEmpty || accountNumber.isEmpty) {
      _showErrorSnackBar('Missing bank details for this pending voucher');
      return;
    }

    // Get voucher amount
    double amount = 0.0;
    if (_voucherDetails != null) {
      amount = (_voucherDetails!.pointsRequired ?? 0).toDouble();
    }

    if (amount <= 0) {
      _showErrorSnackBar('Invalid voucher amount');
      return;
    }

    // Show test payout dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stripe Payout (Test Mode)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No real money transferred',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payout Amount: RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recipient: $bankName\nAccount: $accountNumber',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Confirm to process this test payout via Stripe API.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Payout'),
          ),
        ],
      ),
    );

    if (result != true) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final supabase = SupabaseService().client;

      // Build request body
      final requestBody = {
        'amount': (amount * 100).toInt(),
        'currency': 'myr',
        'bankName': bankName,
        'accountNumber': accountNumber,
        'voucherCode': widget.pendingVoucher.voucherCode,
        'userId': widget.pendingVoucher.userId,
      };

      final response = await supabase.functions
          .invoke('stripe-process-payout-dev', body: requestBody)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Function call timeout - function may not be deployed',
            ),
          );

      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null && responseData['success'] == true) {
        try {
          // Update voucher status to used
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

          _showSuccessSnackBar(
            'Payout processed via Stripe! (Test Mode)\nPayout ID: ${responseData['payoutId']}',
          );

          if (widget.onProcessed != null && mounted) {
            await widget.onProcessed!.call();
          }
        } catch (updateError) {
          if (mounted) {
            _showErrorSnackBar(
              'Payout succeeded but failed to update voucher: $updateError',
            );
          }
        }
      } else {
        final errorMsg =
            responseData?['error'] ??
            responseData?['details'] ??
            'Unknown error';
        if (mounted) {
          _showErrorSnackBar('Stripe payout failed: $errorMsg');
        }
      }
    } catch (e) {
      // Provide helpful error message
      String errorMessage = 'Error processing Stripe payout: $e';
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        errorMessage =
            'Stripe payout function "stripe-process-payout-dev" not found. Please check your Supabase Edge Functions are deployed.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage =
            'Authentication error. Please ensure you are logged in with proper permissions.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      }

      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Bank Transfer'),
          content: Text(
            'Have you completed the bank transfer to ${widget.pendingVoucher.bankName} (${_fullAccountNumber(widget.pendingVoucher.bankAccountNumber)})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Mark Paid'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: widget.theme.error),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    // Show dialog instead of snackbar since widget may be unmounted
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _fullAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return 'N/A';
    return accountNumber;
  }
}
