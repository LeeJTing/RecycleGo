import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/admin/admin_pending_vouchers.dart';

class AdminVoucherHistoryTab extends StatelessWidget {
  final List<RedeemedVouchers> redeemedVouchers;
  final bool isLoading;

  const AdminVoucherHistoryTab({
    super.key,
    required this.redeemedVouchers,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (redeemedVouchers.isEmpty) {
      return Center(
        child: Text(
          'No redemption history',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redemption History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...redeemedVouchers.map(
          (redeemedVoucher) => GestureDetector(
            onTap: () =>
                _showRedemptionDetailsModal(context, theme, redeemedVoucher),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.onPrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code: ${redeemedVoucher.voucherCode}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'User: ${redeemedVoucher.userId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            redeemedVoucher.voucherStatus,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          redeemedVoucher.voucherStatus.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(
                              redeemedVoucher.voucherStatus,
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Redeemed: ${redeemedVoucher.redeemedAt?.toString().split(' ')[0] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRedemptionDetailsModal(
    BuildContext context,
    AppColors theme,
    RedeemedVouchers redeemedVoucher,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            color: theme.surface,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Redemption Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Status Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        redeemedVoucher.voucherStatus,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(
                          redeemedVoucher.voucherStatus,
                        ).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      redeemedVoucher.voucherStatus.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(redeemedVoucher.voucherStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Details Section
                Text(
                  'Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 14),
                // Voucher Code
                _buildModalDetailRow(
                  context: context,
                  theme: theme,
                  icon: Icons.confirmation_number_outlined,
                  label: 'Voucher Code',
                  value: redeemedVoucher.voucherCode,
                  canCopy: true,
                ),
                const SizedBox(height: 12),
                // User ID
                _buildModalDetailRow(
                  context: context,
                  theme: theme,
                  icon: Icons.person_outline,
                  label: 'User ID',
                  value: redeemedVoucher.userId,
                  canCopy: true,
                ),
                const SizedBox(height: 12),
                // Redeemed At
                _buildModalDetailRow(
                  context: context,
                  theme: theme,
                  icon: Icons.access_time_outlined,
                  label: 'Redeemed Date',
                  value: redeemedVoucher.redeemedAt?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 12),
                // Voucher ID
                _buildModalDetailRow(
                  context: context,
                  theme: theme,
                  icon: Icons.card_giftcard,
                  label: 'Voucher ID',
                  value: redeemedVoucher.voucherId ?? 'N/A',
                  canCopy: true,
                ),
                const SizedBox(height: 28),
                // Go to Pending Vouchers Button (if status is pending)
                if (redeemedVoucher.voucherStatus ==
                    RedeemedVoucherStatus.pending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close modal first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPendingVouchers(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text(
                        'Go to Pending Vouchers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow({
    required BuildContext context,
    required AppColors theme,
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.onPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Copied to clipboard!'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Icon(
                Icons.copy_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(RedeemedVoucherStatus status) {
    switch (status) {
      case RedeemedVoucherStatus.pending:
        return Colors.amber;
      case RedeemedVoucherStatus.unused:
        return Colors.orange;
      case RedeemedVoucherStatus.used:
        return Colors.green;
      case RedeemedVoucherStatus.shared:
        return Colors.blue;
    }
  }
}
