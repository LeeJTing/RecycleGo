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
import 'package:recycle_go/controller/voucher/voucher_ctrl.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/widgets/voucher_card.dart';
import 'package:recycle_go/view/admin/voucher_details/admin_voucher_details.dart';
import 'package:recycle_go/view/admin/admin_edit_voucher.dart';

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
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
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
              print("Profile Clicked");
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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final VoucherCtrl _voucherCtrl = VoucherCtrl();
  List<Vouchers> _sampleVouchers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _voucherCtrl.fetchVouchers();
      setState(() {
        _sampleVouchers = _voucherCtrl.vouchers.take(1).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
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
        ],
      ),
    );
  }
}
