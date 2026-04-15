import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                return HomeHeader(
                  name: user?.userName ?? 'User',
                  photoUrl: user?.profilePhoto,
                );
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
            const NearbyBinCard(),
            const SizedBox(height: 24),
            const PurchaseCard(),
          ],
        ),
      ),
    );
  }
}
