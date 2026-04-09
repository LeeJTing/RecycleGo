import 'package:flutter/material.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminVoucherInfoTab extends StatelessWidget {
  final Vouchers voucher;

  const AdminVoucherInfoTab({super.key, required this.voucher});

  String _getDurationRemaining() {
    if (voucher.createdAt == null ||
        voucher.voucherDuration == null ||
        voucher.isInfinite) {
      return 'N/A';
    }

    final createdDate = voucher.createdAt!;
    final now = DateTime.now();
    final daysElapsed = now.difference(createdDate).inDays;
    final daysRemaining = voucher.voucherDuration! - daysElapsed;

    if (daysRemaining < 0) {
      return 'Expired (${daysRemaining.abs()} days ago)';
    } else if (daysRemaining == 0) {
      return 'Expires today';
    } else {
      return '$daysRemaining days left';
    }
  }

  Color _getDurationColor() {
    if (voucher.createdAt == null ||
        voucher.voucherDuration == null ||
        voucher.isInfinite) {
      return Colors.grey;
    }

    final createdDate = voucher.createdAt!;
    final now = DateTime.now();
    final daysElapsed = now.difference(createdDate).inDays;
    final daysRemaining = voucher.voucherDuration! - daysElapsed;

    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voucher Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Voucher ID', voucher.voucherId ?? 'N/A'),
        _buildDetailRow('Points Required', '${voucher.pointsRequired} POINTS'),
        _buildDetailRow('Category', voucher.voucherCategory),
        _buildDetailRow('Number of Vouchers', '${voucher.numberOfVouchers}'),
        // Show duration remaining only if status is active
        if (voucher.voucherStatus == 'active' &&
            !voucher.isInfinite &&
            voucher.voucherDuration != null)
          _buildDurationRemainingRow(),
        _buildDetailRow(
          'Duration',
          voucher.isInfinite
              ? 'Infinite'
              : (voucher.voucherDuration != null
                    ? '${voucher.voucherDuration} days'
                    : 'N/A'),
        ),
        const SizedBox(height: 24),
        Text(
          'Timestamps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Created At',
          voucher.createdAt?.toString().split('.')[0] ?? 'N/A',
        ),
        _buildDetailRow(
          'Updated At',
          voucher.updatedAt?.toString().split('.')[0] ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildDurationRemainingRow() {
    final durationText = _getDurationRemaining();
    final durationColor = _getDurationColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Time Remaining',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: durationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: durationColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    durationColor == Colors.green
                        ? Icons.schedule
                        : durationColor == Colors.orange
                        ? Icons.warning_amber
                        : Icons.error,
                    size: 16,
                    color: durationColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      durationText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: durationColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
