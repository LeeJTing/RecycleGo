import 'package:flutter/material.dart';
import 'package:recycle_go/view/user/bottom_nav_bar.dart';
import 'package:recycle_go/view/user/homePage/home_screen.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/recycle/map_screen.dart';
import 'package:recycle_go/view/user/profile/profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  final int initialIndex;
  const UserMainScreen({super.key, this.initialIndex = 0});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const UserHomeScreen(),
    const UserHomeScreen(),
    const MapScreen(),
    const Center(child: Text("Rewards Page")), // Placeholder for Rewards
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
