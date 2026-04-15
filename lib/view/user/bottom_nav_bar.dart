import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      child: SalomonBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          onTap(index);
        },
        selectedItemColor: theme.primary,
        unselectedItemColor: Colors.black54,
        margin: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: 10),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home_max_outlined),
            title: const Text("Home"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.qr_code_scanner),
            title: const Text("Scan"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.map_outlined),
            title: const Text("Bin"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.card_giftcard),
            title: const Text("Voucher"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text("Profile"),
          ),
        ],
      ),
    );
  }
}
