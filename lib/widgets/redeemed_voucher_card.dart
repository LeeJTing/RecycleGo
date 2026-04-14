import 'package:flutter/material.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/app/app_theme.dart';

class RedeemedVoucherCard extends StatelessWidget {
  final RedeemedVouchers redeemedVoucher;
  final AppColors theme;
  final VoidCallback onStatusChange;
  final VoidCallback onDelete;

  const RedeemedVoucherCard({
    super.key,
    required this.redeemedVoucher,
    required this.theme,
    required this.onStatusChange,
    required this.onDelete,
  });

  String _getStatusLabel() {
    switch (redeemedVoucher.voucherStatus) {
      case RedeemedVoucherStatus.pending:
        return 'Pending';
      case RedeemedVoucherStatus.unused:
        return 'Unused';
      case RedeemedVoucherStatus.used:
        return 'Used';
      case RedeemedVoucherStatus.shared:
        return 'Shared';
    }
  }

  Color _getStatusColor() {
    switch (redeemedVoucher.voucherStatus) {
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

  IconData _getStatusIcon() {
    switch (redeemedVoucher.voucherStatus) {
      case RedeemedVoucherStatus.pending:
        return Icons.schedule;
      case RedeemedVoucherStatus.unused:
        return Icons.pending;
      case RedeemedVoucherStatus.used:
        return Icons.check_circle;
      case RedeemedVoucherStatus.shared:
        return Icons.share;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: ${redeemedVoucher.voucherCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Redeemed: ${redeemedVoucher.redeemedAt != null ? redeemedVoucher.redeemedAt!.toString().split(' ')[0] : 'N/A'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pending') {
                        // Change status to pending
                        _showStatusChangeDialog(
                          context,
                          RedeemedVoucherStatus.pending,
                        );
                      } else if (value == 'unused') {
                        // Change status to unused
                        _showStatusChangeDialog(
                          context,
                          RedeemedVoucherStatus.unused,
                        );
                      } else if (value == 'used') {
                        _showStatusChangeDialog(
                          context,
                          RedeemedVoucherStatus.used,
                        );
                      } else if (value == 'shared') {
                        _showStatusChangeDialog(
                          context,
                          RedeemedVoucherStatus.shared,
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'pending',
                        enabled:
                            redeemedVoucher.voucherStatus !=
                            RedeemedVoucherStatus.pending,
                        child: const Text('Mark as Pending'),
                      ),
                      PopupMenuItem(
                        value: 'unused',
                        enabled:
                            redeemedVoucher.voucherStatus !=
                            RedeemedVoucherStatus.unused,
                        child: const Text('Mark as Unused'),
                      ),
                      PopupMenuItem(
                        value: 'used',
                        enabled:
                            redeemedVoucher.voucherStatus !=
                            RedeemedVoucherStatus.used,
                        child: const Text('Mark as Used'),
                      ),
                      PopupMenuItem(
                        value: 'shared',
                        enabled:
                            redeemedVoucher.voucherStatus !=
                            RedeemedVoucherStatus.shared,
                        child: const Text('Mark as Shared'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: theme.primary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showDeleteDialog,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(
    BuildContext context,
    RedeemedVoucherStatus newStatus,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: Text(
            'Change status to ${_getStatusLabelForEnum(newStatus)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onStatusChange();
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    // This is handled by parent, but we can add a confirmation here too
    onDelete();
  }

  String _getStatusLabelForEnum(RedeemedVoucherStatus status) {
    switch (status) {
      case RedeemedVoucherStatus.pending:
        return 'Pending';
      case RedeemedVoucherStatus.unused:
        return 'Unused';
      case RedeemedVoucherStatus.used:
        return 'Used';
      case RedeemedVoucherStatus.shared:
        return 'Shared';
    }
  }
}
