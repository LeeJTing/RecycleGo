import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/view/voucher/voucher_helpers.dart';

void showRedeemDialog({
  required BuildContext context,
  required Vouchers voucher,
  required Future<void> Function() onRedeem,
}) {
  final theme = AppThemes.color;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Redeem Voucher?'),
        content: Text(
          'Redeem "${voucher.voucherName}" for ${VoucherHelpers.formatWithCommas(voucher.pointsRequired)} points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onRedeem();
            },
            child: const Text('Redeem'),
          ),
        ],
      );
    },
  );
}
