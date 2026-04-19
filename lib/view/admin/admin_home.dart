import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/assets.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/view/admin/inventory/admin_inventory.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/view/admin/appealReview/appeal_review_screen.dart';
import 'package:recycle_go/view/admin/profile/admin_profile_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Notifications.dart';
import 'package:recycle_go/view/admin/admin_dashboard.dart';
import 'appealReview/appeal_review_screen.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  String? _currentAdminId;
  StreamSubscription? _notificationSubscription;

  final List<Widget> _pages = const [
    AdminDashboard(),
    AppealReviewScreen(),
    AdminInventory(),
    StationRegistryScreen(),
    AdminProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>().admin;
      _currentAdminId = admin?.adminId;
      _setupNotificationListener();
    });
  }

  void _setupNotificationListener() {
    if (_currentAdminId == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = NotificationsModel()
        .getAdminNotificationStream(_currentAdminId!)
        .listen((notifications) {
      if (mounted) {
        setState(() {
          _unreadCount = notifications
              .where((n) => n.notificationStatus.toLowerCase() == 'unread')
              .length;
        });
      }
    }, onError: (e) {
      debugPrint('Error in notification stream: $e');
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: _buildAppBar(theme),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _bottomNavigator(theme),
    );
  }

  // ---------------- BOTTOM NAV ----------------

  Widget _bottomNavigator(AppColors theme) {
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
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: theme.primary,
          unselectedItemColor: theme.hint,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              title: const Text("Home"),
            ),

            // Appeals
            SalomonBottomBarItem(
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(_unreadCount.toString()),
                backgroundColor: theme.error,
                child: const Icon(Icons.check_circle_outline),
              ),
              activeIcon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(_unreadCount.toString()),
                backgroundColor: theme.error,
                child: const Icon(Icons.check_circle),
              ),
              title: const Text("Appeals"),
            ),

            // PURCHASE
            SalomonBottomBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              title: const Text("Items"),
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.location_on_outlined),
              activeIcon: const Icon(Icons.location_on),
              title: const Text("Stations"),
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              title: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }

  String get _currentTitle {
    switch (_currentIndex) {
      case 0: return "Admin Dashboard";
      case 1: return "Appeal Review";
      case 2: return "Admin Inventory";
      case 3: return "Station Registry";
      case 4: return "Admin Profile";
      default: return "";
    }
  }

  AppBar _buildAppBar(AppColors theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.onPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 72,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _currentIndex = 0),
            icon: Image.asset(AppAssets.logo, height: 36),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentTitle, style: TextDesign.appBarTitle()),
              if (_unreadCount > 0)
                Text(
                  "$_unreadCount unread notifications",
                  style: TextDesign.label(
                    color: theme.primary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),

      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: theme.onSurface,
                size: 28,
              ),
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  Routes.adminNotification,
                );
                // No need to manually reload count as stream handles it
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.surface, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () => setState(() => _currentIndex = 4),
            icon: Consumer<AdminProvider>(
              builder: (context, adminProvider, _) {
                final url = adminProvider.getProfileImageUrl();

                return CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.primary.withOpacity(0.1),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, color: theme.primary),
                    ),
                  ),
                );
              },
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
