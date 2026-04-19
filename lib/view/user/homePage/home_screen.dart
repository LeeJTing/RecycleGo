import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/user/bottom_nav_bar.dart';
import 'package:recycle_go/view/user/homePage/widgets/home_header.dart';
import 'package:recycle_go/view/user/homePage/widgets/score_cards.dart';
import 'package:recycle_go/view/user/homePage/widgets/scan_button.dart';
import 'package:recycle_go/view/user/homePage/widgets/nearby_bin_card.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/recycle/map_screen.dart';
import 'package:recycle_go/view/user/profile/profile_screen.dart';
import 'package:recycle_go/view/voucher/voucher_main_page.dart';
import 'package:recycle_go/view/user/homePage/widgets/purchase_card.dart';
import 'package:recycle_go/view/user/appeal/widgets/appeal_status_card.dart';

import '../../../app/TextDesign.dart';
import '../appeal/appeal_list_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final int initialIndex;
  const UserHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final List<Widget> _pages = [
      const _HomeContent(),
      const QrScanScreen(),
      const MapScreen(),
      VoucherMainPage(
        currentPoints: user?.totalPoints ?? 0,
        goalPoints: 1000,
        memberRank: 'Bronze',
        nextRank: 'Silver',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<Appeals> _appeals = [];
  bool _isLoadingAppeals = true;

  @override
  void initState() {
    super.initState();
    _fetchAppeals();
  }

  Future<void> _fetchAppeals() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.userId == null) return;

    try {
      final appeals = await AppealsModel().getUserAppeals(
        userProvider.user!.userId!,
      );
      if (mounted) {
        setState(() {
          _appeals = appeals;
          _isLoadingAppeals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAppeals = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchAppeals,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                onProfileTap: () {
                  Navigator.pushReplacementNamed(context, Routes.userProfile);
                },
              ),
              const SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return ScoreCards(
                    totalPoints: userProvider.user?.totalPoints ?? 0,
                  );
                },
              ),
              const SizedBox(height: 24),
              const ScanButton(),
              const SizedBox(height: 24),

              Text(
                "Recent Submissions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Recent Submissions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),


              const SizedBox(height: 24),
// ... the rest (ElevatedButton, NearbyBinCard, PurchaseCard)
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final userProvider = context.read<UserProvider>();
                  final userId = userProvider.user?.userId;

                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppealListScreen(
                          initialAppeals: _appeals,
                          userId: userId,
                        ),
                      ),
                    );
                  } else {
                    print("Error: User ID is null");
                  }
                },
                child: const Text("View Appeals"),
              ),
              const NearbyBinCard(),
              const SizedBox(height: 24),
              const PurchaseCard(),
            ],
          ),
        ),
      ),
    );
  }
}
