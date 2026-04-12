import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/view/voucher/redeemed_voucher_dialogs.dart';

class RedeemedVoucherCard extends StatelessWidget {
  final RedeemedVouchers redeemedVoucher;
  final VoidCallback onSharePressed;
  final VoidCallback onUsePressed;
  final bool showShareButton;
  final bool showUseButton;

  const RedeemedVoucherCard({
    super.key,
    required this.redeemedVoucher,
    required this.onSharePressed,
    required this.onUsePressed,
    this.showShareButton = true,
    this.showUseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title and Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voucher Code',
                        style: TextDesign.smallText(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        redeemedVoucher.voucherCode,
                        style: TextDesign.headingTwo(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Details'),
                      onTap: () {
                        RedeemedVoucherDialogs.showDetailsDialog(
                          context: context,
                          redeemedVoucher: redeemedVoucher,
                        );
                      },
                    ),
                  ],
                  child: Icon(Icons.more_vert, color: theme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Badge
            Chip(
              label: Text(
                redeemedVoucher.voucherStatus.dbValue.toUpperCase(),
                style: TextDesign.smallText(
                  color: RedeemedVoucherDialogs.getStatusColor(
                    redeemedVoucher.voucherStatus,
                  ),
                ),
              ),
              backgroundColor: RedeemedVoucherDialogs.getStatusColor(
                redeemedVoucher.voucherStatus,
              ).withOpacity(0.1),
            ),
            const SizedBox(height: 12),

            // Redeemed Date
            Text(
              'Redeemed: ${redeemedVoucher.redeemedAt?.toString().split('.')[0] ?? 'N/A'}',
              style: TextDesign.smallText(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showShareButton)
                  ElevatedButton.icon(
                    onPressed: onSharePressed,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (showUseButton)
                  ElevatedButton.icon(
                    onPressed: onUsePressed,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Use'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
