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

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consumer ensures only this part rebuilds when user data changes
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
                    return ScoreCards(totalPoints: userProvider.user?.totalPoints ?? 0);
                  },
                ),
                const SizedBox(height: 24),
                
                const ScanButton(), // Constant to prevent rebuilds
                const SizedBox(height: 24),
                
                SlideTransition(
                  position: _slideAnimation,
                  child: const NearbyBinCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
