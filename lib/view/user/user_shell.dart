import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/user/bottom_nav_bar.dart';
import 'package:recycle_go/view/user/homePage/home_screen.dart';
import 'package:recycle_go/view/voucher/voucher_main_page.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/TextDesign.dart';

class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _currentIndex = 0;

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final screenTitles = ['Home', 'Scan', 'Bin', 'Voucher', 'Profile'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
          child: Image.asset('assets/images/logo.webp', width: 28, height: 28),
        ),
        title: Text(
          screenTitles[_currentIndex],
          style: TextDesign.normalText(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
      body: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    switch (_currentIndex) {
      case 0: // Home
        return const UserHomeScreen();

      case 1: // Scan
        return const Center(child: Text('Scan Screen - Coming Soon'));

      case 2: // Bin
        return const Center(child: Text('Bin Screen - Coming Soon'));

      case 3: // Voucher
        return VoucherMainPage(
          currentPoints: userProvider.user?.totalPoints ?? 0,
          goalPoints: 2000,
          memberRank: 'BRONZE MEMBER',
          nextRank: 'SILVER RANK',
        );

      case 4: // Profile
        return const Center(child: Text('Profile Screen - Coming Soon'));

      default:
        return const SizedBox.shrink();
    }
  }
}
