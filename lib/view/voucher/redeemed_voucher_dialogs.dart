import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class RedeemedVoucherDialogs {
  // Show details dialog with QR code
  static void showDetailsDialog({
    required BuildContext context,
    required RedeemedVouchers redeemedVoucher,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Voucher Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code:', style: TextDesign.normalText()),
              SelectableText(redeemedVoucher.voucherCode),
              const SizedBox(height: 16),
              Text('Status:', style: TextDesign.normalText()),
              Text(
                redeemedVoucher.voucherStatus.dbValue.toUpperCase(),
                style: TextDesign.smallText(
                  color: _getStatusColor(redeemedVoucher.voucherStatus),
                ),
              ),
              // Only show QR code if status is not "used"
              if (redeemedVoucher.voucherStatus !=
                  RedeemedVoucherStatus.used) ...[
                const SizedBox(height: 16),
                Text('QR Code:', style: TextDesign.normalText()),
                const SizedBox(height: 8),
                QRCodeHelpers.buildQRCode(redeemedVoucher.voucherCode),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show share confirmation dialog
  static void showShareConfirmation({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Voucher?'),
          content: const Text(
            'Are you sure you want to share this voucher? Others will be able to use it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  // Show use voucher confirmation dialog
  static void showUseVoucherDialog({
    required BuildContext context,
    required RedeemedVouchers redeemedVoucher,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use This Voucher?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to use this voucher?',
                style: TextDesign.normalText(),
              ),
              const SizedBox(height: 16),
              SelectableText(
                redeemedVoucher.voucherCode,
                style: TextDesign.headingTwo(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Get status color based on redemption status
  static Color _getStatusColor(RedeemedVoucherStatus status) {
    switch (status) {
      case RedeemedVoucherStatus.pending:
        return Colors.amber;
      case RedeemedVoucherStatus.unused:
        return Colors.blue;
      case RedeemedVoucherStatus.used:
        return Colors.green;
      case RedeemedVoucherStatus.shared:
        return Colors.purple;
    }
  }

  static Color getStatusColor(RedeemedVoucherStatus status) =>
      _getStatusColor(status);
}
