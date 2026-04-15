import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/widgets/voucher_card.dart';
import 'admin_add_voucher.dart';
import 'admin_edit_voucher.dart';
import 'voucher_details/admin_voucher_details.dart';

class AdminVoucherManagement extends StatefulWidget {
  const AdminVoucherManagement({super.key});

  @override
  State<AdminVoucherManagement> createState() => _AdminVoucherManagementState();
}

class _AdminVoucherManagementState extends State<AdminVoucherManagement> {
  final VoucherCtrl voucherCtrl = VoucherCtrl();
  String filterStatus = 'all';
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadVouchers();
  }

  Future<void> _initializeAndLoadVouchers() async {
    // Check if admin is logged in
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.admin != null) {
      await _loadVouchers();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin not authenticated")),
        );
      }
    }
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      await voucherCtrl.fetchVouchers();
    } catch (e) {
      // Handle error silently
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Vouchers> getFilteredVouchers() {
    List<Vouchers> result = voucherCtrl.vouchers;

    if (filterStatus != 'all') {
      result = result.where((v) => v.voucherStatus == filterStatus).toList();
    }

    if (searchController.text.isNotEmpty) {
      result = result
          .where(
            (v) => v.voucherName.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Check if admin is authenticated
    final admin = Provider.of<AdminProvider>(context).admin;

    if (admin == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Admin not authenticated"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final theme = AppThemes.color;
    final filteredVouchers = getFilteredVouchers();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by voucher name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterBtn('All', 'all', theme, voucherCtrl.vouchers.length),
                const SizedBox(width: 8),
                _filterBtn(
                  'Active',
                  'active',
                  theme,
                  voucherCtrl.vouchers
                      .where((v) => v.voucherStatus == 'active')
                      .length,
                ),
                const SizedBox(width: 8),
                _filterBtn(
                  'Inactive',
                  'inactive',
                  theme,
                  voucherCtrl.vouchers
                      .where((v) => v.voucherStatus == 'inactive')
                      .length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vouchers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAddVoucher(),
                      ),
                    ).then((_) => _loadVouchers());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVouchers.isEmpty
                ? const Center(child: Text('No vouchers found'))
                : ListView.builder(
                    itemCount: filteredVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = filteredVouchers[index];
                      final voucherIndex = voucherCtrl.vouchers.indexOf(
                        voucher,
                      );
                      final theme = AppThemes.color;

                      return VoucherCard(
                        voucher: voucher,
                        theme: theme,
                        showIcon: true,
                        showDescription: true,
                        showCreatedDate: true,
                        showDuration: true,
                        onToggleStatus: () async {
                          try {
                            final wasActive = voucher.voucherStatus == 'active';
                            await voucherCtrl.toggleVoucherStatus(
                              voucher.voucherId ?? '',
                            );
                            // Reload vouchers to update UI with new status
                            await voucherCtrl.fetchVouchers();
                            setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    wasActive
                                        ? 'Voucher inactivated'
                                        : 'Voucher activated',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminEditVoucher(
                                voucher: voucher,
                                index: voucherIndex,
                              ),
                            ),
                          ).then((_) => _loadVouchers());
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Voucher'),
                                content: Text(
                                  'Are you sure you want to delete "${voucher.voucherName}"?',
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
                                        await voucherCtrl.deleteVoucher(
                                          voucher.voucherId ?? '',
                                        );
                                        await _loadVouchers();
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Voucher deleted successfully',
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
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminVoucherDetails(voucher: voucher),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label, String status, AppColors theme, int count) {
    bool isActive = filterStatus == status;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => filterStatus = status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? theme.primary : Colors.grey[200],
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
