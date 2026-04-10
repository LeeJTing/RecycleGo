import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';

class VoucherCard extends StatelessWidget {
  final Vouchers voucher;
  final AppColors theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback? onViewDetails;
  final bool showIcon;
  final bool showDescription;
  final bool showCreatedDate;
  final bool showDuration;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.onViewDetails,
    this.showIcon = true,
    this.showDescription = true,
    this.showCreatedDate = false,
    this.showDuration = false,
  });

  /// Get icon and color based on voucher category
  Map<String, dynamic> _getCategoryIconAndColor() {
    switch (voucher.voucherCategory.toLowerCase()) {
      case 'food':
        return {
          'icon': Icons.restaurant,
          'color': const Color(0xFFFF6B6B), // Red/Orange
        };
      case 'shopping':
        return {
          'icon': Icons.shopping_bag,
          'color': const Color(0xFF4ECDC4), // Teal
        };
      case 'exchange':
        return {
          'icon': Icons.attach_money,
          'color': const Color(0xFF2ECC71), // Green
        };
      default:
        return {
          'icon': Icons.card_giftcard,
          'color': const Color(0xFF6C5CE7), // Purple
        };
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
          // Top Row: Icon/Name + Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showIcon)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryIconAndColor()['color']
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIconAndColor()['icon'],
                          color: _getCategoryIconAndColor()['color'],
                          size: 24,
                        ),
                      ),
                    if (showIcon) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.voucherName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (showDescription && voucher.description != null)
                            Text(
                              voucher.description!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onToggleStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: voucher.voucherStatus == 'active'
                      ? Colors.red
                      : Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  voucher.voucherStatus == 'active' ? 'Inactivate' : 'Activate',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              // Triple-dot info button
              IconButton(
                onPressed: onViewDetails,
                icon: Icon(Icons.more_vert, color: theme.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date and Duration Info (if needed)
          if (showCreatedDate || showDuration) ...[
            if (showCreatedDate)
              Text(
                voucher.createdAt != null
                    ? 'Voucher Created At: ${voucher.createdAt!.toString().split(' ')[0]}'
                    : 'Date not available',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            if (showDuration)
              Text(
                voucher.isInfinite
                    ? 'Duration: Infinite'
                    : 'Duration: ${voucher.voucherDuration ?? 'N/A'} days',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            const SizedBox(height: 12),
          ],

          // Bottom Row: Points + Edit/Delete Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${voucher.pointsRequired} POINTS',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
