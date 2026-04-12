import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/view/voucher/voucher_helpers.dart';

class VoucherCard extends StatelessWidget {
  final Vouchers voucher;
  final String category;
  final VoidCallback onRedeemPressed;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.category,
    required this.onRedeemPressed,
  });

  @override
  Widget build(BuildContext context) {
    AppColors theme = AppThemes.color;

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
            // Top row: Icon and Category
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: VoucherHelpers.getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: VoucherHelpers.getCategoryIcon(category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextDesign.smallText(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.voucherName,
                        style: TextDesign.headingTwo(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: Points and Redeem button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VoucherHelpers.formatWithCommas(voucher.pointsRequired),
                      style: TextDesign.headingTwo(
                        color: theme.primary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'POINTS',
                      style: TextDesign.smallText(color: Colors.grey[500]),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onRedeemPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Redeem',
                    style: TextDesign.smallText(color: theme.onPrimary),
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
