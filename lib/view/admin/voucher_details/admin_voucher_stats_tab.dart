import 'package:flutter/material.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/app/app_theme.dart';

class AdminVoucherStatsTab extends StatelessWidget {
  final List<RedeemedVouchers> redeemedVouchers;
  final int totalVouchersAvailable;

  const AdminVoucherStatsTab({
    super.key,
    required this.redeemedVouchers,
    required this.totalVouchersAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final totalRedeemed = redeemedVouchers.length;
    final unused = redeemedVouchers
        .where((v) => v.voucherStatus == RedeemedVoucherStatus.unused)
        .length;
    final used = redeemedVouchers
        .where((v) => v.voucherStatus == RedeemedVoucherStatus.used)
        .length;
    final shared = redeemedVouchers
        .where((v) => v.voucherStatus == RedeemedVoucherStatus.shared)
        .length;

    // Redemption rate: total redeemed / total available
    final redemptionRate = totalVouchersAvailable > 0
        ? (totalRedeemed / totalVouchersAvailable * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redemption Statistics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        // Status Breakdown Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total Redeemed',
                totalRedeemed.toString(),
                Colors.blue,
                Icons.redeem,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Available',
                totalVouchersAvailable.toString(),
                Colors.cyan,
                Icons.inventory_2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Unused',
                unused.toString(),
                Colors.orange,
                Icons.block,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Used',
                used.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Shared',
                shared.toString(),
                Colors.purple,
                Icons.share,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Remaining',
                (totalVouchersAvailable - totalRedeemed).toString(),
                Colors.grey,
                Icons.hourglass_empty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Redemption Rate Visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.onPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Redemption Rate',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              // Overall Redemption Rate (pie-like visual)
              _buildRedemptioinRateBar(
                label: 'Overall Redemption Rate',
                redeemed: totalRedeemed,
                total: totalVouchersAvailable,
                color: theme.primary,
              ),
              const SizedBox(height: 20),
              // Breakdown of redeemed vouchers
              if (totalRedeemed > 0) ...[
                Text(
                  'Breakdown of Redeemed Vouchers',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  label: 'Unused',
                  value: unused,
                  total: totalRedeemed,
                  color: Colors.orange,
                ),
                const SizedBox(height: 14),
                _buildProgressBar(
                  label: 'Used',
                  value: used,
                  total: totalRedeemed,
                  color: Colors.green,
                ),
                const SizedBox(height: 14),
                _buildProgressBar(
                  label: 'Shared',
                  value: shared,
                  total: totalRedeemed,
                  color: Colors.blue,
                ),
              ] else ...[
                Text(
                  'No redeemed vouchers yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              // Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withOpacity(0.08),
                      theme.primary.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRateInfo(
                          'Redemption Rate',
                          '${redemptionRate.toStringAsFixed(1)}%',
                          theme.primary,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildRateInfo(
                          'Redeemed',
                          '$totalRedeemed/$totalVouchersAvailable',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptioinRateBar({
    required String label,
    required int redeemed,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (redeemed / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 14,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRateInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatCard(
    AppColors theme,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
