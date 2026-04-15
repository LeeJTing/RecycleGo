import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/view/voucher/helpers/voucher_status_helpers.dart';

/// Widget for displaying voucher not found screen
class VoucherNotFoundWidget extends StatelessWidget {
  const VoucherNotFoundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: theme.error),
            const SizedBox(height: 16),
            Text('Voucher Not Found', style: TextDesign.headingTwo()),
            const SizedBox(height: 8),
            Text(
              'The voucher code could not be found.\nPlease check and try again.',
              textAlign: TextAlign.center,
              style: TextDesign.smallText(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying voucher status badge
class VoucherStatusBadge extends StatelessWidget {
  final RedeemedVoucherStatus status;

  const VoucherStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = VoucherStatusHelpers.getStatusColor(status);
    final bgColor = VoucherStatusHelpers.getStatusBackgroundColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voucher Status',
            style: TextDesign.smallText(color: statusColor),
          ),
          const SizedBox(height: 4),
          Text(
            status.dbValue.toUpperCase(),
            style: TextDesign.headingTwo(color: statusColor, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying voucher details (code, dates, etc.)
class VoucherDetailsWidget extends StatelessWidget {
  final RedeemedVouchers voucher;

  const VoucherDetailsWidget({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Code', voucher.voucherCode, monospace: true),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Redeemed Date',
            voucher.redeemedAt?.toString().split('.')[0] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool monospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextDesign.smallText(color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextDesign.smallText(color: Colors.grey[800], fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying bank transfer details (for exchange vouchers)
class BankTransferDetailWidget extends StatelessWidget {
  final RedeemedVouchers voucher;
  final Vouchers? voucherDetails;

  const BankTransferDetailWidget({
    super.key,
    required this.voucher,
    required this.voucherDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isExchange = VoucherStatusHelpers.isExchangeVoucher(
      voucherDetails?.voucherCategory,
    );

    if (!isExchange) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Transfer Details',
            style: TextDesign.headingTwo(color: Colors.blue[700], fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (voucher.bankName != null && voucher.bankName!.isNotEmpty)
            Column(
              children: [
                _buildDetailRow('Bank Name', voucher.bankName ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Account Number',
                  VoucherStatusHelpers.maskAccountNumber(
                    voucher.bankAccountNumber ?? 'N/A',
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bank information not saved. Click "Yes, Use It" to enter it.',
                      style: TextDesign.smallText(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextDesign.smallText(color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextDesign.smallText(color: Colors.grey[800], fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying action buttons
class VoucherActionButtonsWidget extends StatelessWidget {
  final bool isAlreadyUsed;
  final VoidCallback onUseVoucher;

  const VoucherActionButtonsWidget({
    super.key,
    required this.isAlreadyUsed,
    required this.onUseVoucher,
  });

  @override
  Widget build(BuildContext context) {
    if (isAlreadyUsed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            Text(
              'Voucher Already Used',
              style: TextDesign.normalText(color: Colors.green, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'This voucher has already been redeemed.',
              style: TextDesign.smallText(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Do you want to use this voucher?',
          textAlign: TextAlign.center,
          style: TextDesign.normalText(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onUseVoucher,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Yes, Use It',
            style: TextDesign.normalText(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text('Cancel', style: TextDesign.normalText(fontSize: 16)),
        ),
      ],
    );
  }
}
