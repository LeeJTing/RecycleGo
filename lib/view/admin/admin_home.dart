import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/assets.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/admin/admin_inventory.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:recycle_go/view/admin/verify_recycle_item.dart';
import 'package:recycle_go/view/admin/request_admin.dart';
import 'package:recycle_go/view/admin/admin_view_purchase.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/models/Vouchers.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/widgets/voucher_card.dart';
import 'package:recycle_go/view/admin/voucher_details/admin_voucher_details.dart';
import 'package:recycle_go/view/admin/admin_edit_voucher.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:recycle_go/view/admin/widgets/pending_vouchers_section.dart';
import 'package:recycle_go/view/admin/admin_pending_vouchers.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0; // Default to 'Verify' as per your UI
  final _supabase = SupabaseService().client;
  // A list of the different 'Bodies' for each navigation button
  final List<Widget> _pages = [
    const AdminDashboard(), //AdminDashboard()
    const AdminInventory(),
    const RequestAdmin(),
    const AdminViewPurchase(),
    const Center(child: Text("Profile Settings Content")),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: appBar(theme),
      body: _pages[_currentIndex],
      bottomNavigationBar: bottomNavigator(theme),
    );
  }

  Container bottomNavigator(AppColors theme) {
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.02,
            vertical: size.height * 0.01,
          ),
          child: SalomonBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: theme.primary,
            unselectedItemColor: theme.hint,
            itemPadding: EdgeInsets.symmetric(
              vertical: size.height * 0.02,
              horizontal: size.width * 0.02,
            ),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                title: const Text("Home"),
              ),
              SalomonBottomBarItem(
                icon: Badge(
                  label: const Text('9'),
                  backgroundColor: theme.error,
                  child: const Icon(Icons.check_circle_outline),
                ),
                activeIcon: Badge(
                  label: const Text('9'),
                  backgroundColor: theme.error,
                  child: const Icon(Icons.check_circle),
                ),
                title: const Text("Verify"),
              ),
              SalomonBottomBarItem(
                icon: Badge(
                  label: const Text("9"),
                  backgroundColor: theme.error,
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: Badge(
                  label: const Text("9"),
                  backgroundColor: theme.error,
                  child: const Icon(Icons.receipt_long),
                ),
                title: const Text("Purchase"),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.confirmation_number_outlined),
                activeIcon: const Icon(Icons.confirmation_number),
                title: const Text("Voucher"),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person), // Matches Admin profile
                title: const Text("Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar appBar(AppColors theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
            icon: Image.asset(AppAssets.logo, height: 36),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Dashboard", style: TextDesign.appBarTitle()),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, Routes.adminNotification);
          },
          icon: Badge(
            label: const Text('9'), // Matches the "9" pending items in your UI
            child: Icon(Icons.notifications_none, color: theme.onSurface),
          ),
        ),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(
            right: 10.0,
          ), // Moves the button away from the screen edge
          child: IconButton(
            onPressed: () {
              // Profile button
            },
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: theme.primary.withOpacity(0.1),
              child: Icon(Icons.person, color: theme.primary, size: 24),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 72,
      backgroundColor: theme.onPrimary,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  List<Vouchers> _sampleVouchers = [];
  List<RedeemedVouchers> _pendingVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _voucherCtrl.fetchVouchers();
      await _loadPendingVouchers();

      if (_voucherCtrl.vouchers.isNotEmpty) {
        setState(() {
          _sampleVouchers = _voucherCtrl.vouchers.take(1).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading vouchers'),
            backgroundColor: theme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadPendingVouchers() async {
    try {
      final supabase = SupabaseService().client;
      final response = await supabase
          .from('redeemedvouchers')
          .select()
          .eq('voucher_status', 'pending')
          .order('redeemed_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingVouchers = (response as List)
              .map((v) => RedeemedVouchers.fromJson(v))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = AppThemes.color;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending vouchers: $e'),
            backgroundColor: theme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadVouchers() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Search by ID or User...",
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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerifyRecycleItem()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Verify Recycle Item"),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Available Vouchers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminVoucherManagement(),
                    ),
                  );
                },
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
          if (_sampleVouchers.isEmpty)
            Center(
              child: Text(
                "No vouchers available",
                style: TextStyle(color: theme.hint),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sampleVouchers.length,
              itemBuilder: (context, index) {
                return VoucherCard(
                  voucher: _sampleVouchers[index],
                  theme: theme,
                  onEdit: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminEditVoucher(
                          voucher: _sampleVouchers[index],
                          index: index,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadVouchers();
                    }
                  },
                  onDelete: () {
                    showDeleteVoucherDialog(
                      context: context,
                      voucher: _sampleVouchers[index],
                      voucherCtrl: _voucherCtrl,
                      onDeleted: _loadVouchers,
                    );
                  },
                  onToggleStatus: () async {
                    try {
                      await _voucherCtrl.toggleVoucherStatus(
                        _sampleVouchers[index].voucherId ?? '',
                      );

                      if (!mounted) return;

                      await _loadVouchers();

                      if (!mounted) return;

                      final newStatus = _voucherCtrl.vouchers
                          .firstWhere(
                            (v) =>
                                v.voucherId == _sampleVouchers[index].voucherId,
                          )
                          .voucherStatus;
                      final message =
                          (newStatus ?? '').toLowerCase() == 'active'
                          ? 'Voucher activated'
                          : 'Voucher inactivated';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        final theme = AppThemes.color;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: theme.error,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminVoucherDetails(
                          voucher: _sampleVouchers[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 32),
          PendingVouchersSection(
            pendingVouchers: _pendingVouchers,
            theme: theme,
            maxItems: 1,
            onViewAll: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPendingVouchers()),
              );
              await _loadPendingVouchers();
            },
            onProcessed: _loadPendingVouchers,
          ),
        ],
      ),
    );
  }
}
