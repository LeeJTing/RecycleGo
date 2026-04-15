import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/view/admin/widgets/pending_voucher_card.dart';

class PendingVouchersSection extends StatelessWidget {
  final List<RedeemedVouchers> pendingVouchers;
  final AppColors theme;
  final VoidCallback? onViewAll;
  final VoidCallback? onProcessed;

  const PendingVouchersSection({
    super.key,
    required this.pendingVouchers,
    required this.theme,
    this.onViewAll,
    this.onProcessed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Pending Vouchers",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                "View All",
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pendingVouchers.isEmpty)
          Center(
            child: Text(
              "No pending vouchers",
              style: TextStyle(color: theme.hint),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingVouchers.length,
            itemBuilder: (context, index) {
              return PendingVoucherCard(
                pendingVoucher: pendingVouchers[index],
                theme: theme,
                onProcessed: onProcessed,
              );
            },
          ),
      ],
    );
  }
}
