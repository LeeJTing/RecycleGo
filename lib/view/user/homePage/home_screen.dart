import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/user/homePage/widgets/home_header.dart';
import 'package:recycle_go/view/user/homePage/widgets/score_cards.dart';
import 'package:recycle_go/view/user/homePage/widgets/scan_button.dart';
import 'package:recycle_go/view/user/homePage/widgets/nearby_bin_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
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
          ],
        ),
      ),
    );
  }
}
