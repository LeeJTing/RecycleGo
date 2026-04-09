import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/widgets/redeemed_voucher_card.dart';

class AdminRedeemedVouchers extends StatefulWidget {
  const AdminRedeemedVouchers({super.key});

  @override
  State<AdminRedeemedVouchers> createState() => _AdminRedeemedVouchersState();
}

class _AdminRedeemedVouchersState extends State<AdminRedeemedVouchers> {
  final RedeemVoucherCtrl _redeemedVoucherCtrl = RedeemVoucherCtrl();
  bool _isLoading = true;
  RedeemedVoucherStatus? _filterStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRedeemedVouchers();
  }

  Future<void> _loadRedeemedVouchers() async {
    try {
      await _redeemedVoucherCtrl.fetchRedeemedVouchers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  List<RedeemedVouchers> _getFilteredVouchers() {
    var filtered = _redeemedVoucherCtrl.redeemedVouchers;

    if (_filterStatus != null) {
      filtered = filtered
          .where((v) => v.voucherStatus == _filterStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (v) =>
                v.voucherCode.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                v.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                v.voucherId.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final filteredVouchers = _getFilteredVouchers();

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Redeemed Vouchers', style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by code, user ID, or voucher ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.onPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStatus == null,
                    onSelected: (selected) {
                      setState(() => _filterStatus = null);
                    },
                    backgroundColor: theme.onPrimary,
                    selectedColor: theme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      'Unused (${_redeemedVoucherCtrl.getCountByStatus(RedeemedVoucherStatus.unused)})',
                    ),
                    selected: _filterStatus == RedeemedVoucherStatus.unused,
                    onSelected: (selected) {
                      setState(
                        () => _filterStatus = RedeemedVoucherStatus.unused,
                      );
                    },
                    backgroundColor: theme.onPrimary,
                    selectedColor: Colors.orange.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      'Used (${_redeemedVoucherCtrl.getCountByStatus(RedeemedVoucherStatus.used)})',
                    ),
                    selected: _filterStatus == RedeemedVoucherStatus.used,
                    onSelected: (selected) {
                      setState(
                        () => _filterStatus = RedeemedVoucherStatus.used,
                      );
                    },
                    backgroundColor: theme.onPrimary,
                    selectedColor: Colors.green.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      'Shared (${_redeemedVoucherCtrl.getCountByStatus(RedeemedVoucherStatus.shared)})',
                    ),
                    selected: _filterStatus == RedeemedVoucherStatus.shared,
                    onSelected: (selected) {
                      setState(
                        () => _filterStatus = RedeemedVoucherStatus.shared,
                      );
                    },
                    backgroundColor: theme.onPrimary,
                    selectedColor: Colors.blue.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  theme,
                  'Total',
                  _redeemedVoucherCtrl.redeemedVouchers.length.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  theme,
                  'Unused',
                  _redeemedVoucherCtrl
                      .getCountByStatus(RedeemedVoucherStatus.unused)
                      .toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  theme,
                  'Used',
                  _redeemedVoucherCtrl
                      .getCountByStatus(RedeemedVoucherStatus.used)
                      .toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  theme,
                  'Shared',
                  _redeemedVoucherCtrl
                      .getCountByStatus(RedeemedVoucherStatus.shared)
                      .toString(),
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Redeemed Vouchers List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (filteredVouchers.isEmpty)
              Center(
                child: Text(
                  'No redeemed vouchers found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Column(
                children: filteredVouchers.map((voucher) {
                  return RedeemedVoucherCard(
                    redeemedVoucher: voucher,
                    theme: theme,
                    onStatusChange: () async {
                      try {
                        // Cycle through statuses
                        final newStatus =
                            voucher.voucherStatus ==
                                RedeemedVoucherStatus.unused
                            ? RedeemedVoucherStatus.used
                            : voucher.voucherStatus ==
                                  RedeemedVoucherStatus.used
                            ? RedeemedVoucherStatus.shared
                            : RedeemedVoucherStatus.unused;
                        await _redeemedVoucherCtrl.updateRedeemedVoucherStatus(
                          voucher.voucherCode,
                          newStatus,
                        );
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to $newStatus'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    onDelete: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Redeemed Voucher'),
                            content: Text(
                              'Are you sure you want to delete this redeemed voucher (${voucher.voucherCode})?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await _redeemedVoucherCtrl
                                        .deleteRedeemedVoucher(
                                          voucher.voucherCode,
                                        );
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Redeemed voucher deleted',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    AppColors theme,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
