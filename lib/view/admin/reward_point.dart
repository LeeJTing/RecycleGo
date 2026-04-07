import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class RewardPointScreen extends StatelessWidget {
  const RewardPointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    // --- Data Extraction ---
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> data = (args != null && args is Map<String, dynamic>)
        ? args
        : {
      'points_earned': 25,
      'total_points': 2480,
      'current_streak_days': 12,
      'last_recycle_name': 'Plastic Bottles',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. TOP BACKGROUND GRADIENT (Subtle Mesh)
          _buildMeshBackground(theme),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeaderNav(context, theme),

                  // 2. HERO ANIMATED ICON
                  _buildHeroSection(theme),
                  const SizedBox(height: 24),

                  // 3. GLASSMORPHIC VERIFICATION CARD
                  _buildVerificationCard(data['last_recycle_name'], theme),
                  const SizedBox(height: 24),

                  // 4. NEON REWARD CARD
                  _buildRewardCard(data['points_earned'], theme),
                  const SizedBox(height: 24),

                  // 5. STATS GRID
                  Row(
                    children: [
                      _buildStatTile("MY POINTS", data['total_points'].toString(), Icons.bolt, theme),
                      const SizedBox(width: 16),
                      _buildStatTile("STREAK", "${data['current_streak_days']} days", Icons.whatshot, theme),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 6. ACTION BUTTONS
                  _buildNavigationRow(theme),
                  const SizedBox(height: 20),
                  _buildSubmitButton(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildMeshBackground(AppColors theme) {
    return Positioned(
      top: -100,
      left: 0,
      right: 0,
      child: Container(
        height: 450,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              theme.success.withOpacity(0.15),
              Colors.white,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNav(BuildContext context, AppColors theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        Row(
          children: [
            Icon(Icons.notifications_none_outlined, color: theme.hint),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/user_avatar.png'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroSection(AppColors theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular Pulse Effect
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.success.withOpacity(0.1), width: 2),
              ),
            ),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: theme.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.success.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationCard(String itemName, AppColors theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7), // Soft amber/cream
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.warning.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: theme.warning, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Item Verified", style: TextDesign.mediumText().copyWith(fontWeight: FontWeight.bold)),
                Text(
                  "Your submission for $itemName has been approved. Points added!",
                  style: TextDesign.smallText(color: theme.hint),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardCard(int points, AppColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D16B), Color(0xFF00B15B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: theme.success.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Text("RECYCLE BONUS UNLOCKED",
              style: TextDesign.badgeText(color: Colors.white.withOpacity(0.8)).copyWith(letterSpacing: 1.2, fontSize: 10)),
          const SizedBox(height: 12),
          Text(
            "+$points",
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("🔥 7 DAY STREAK +10 BONUS",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, AppColors theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: icon == Icons.bolt ? Colors.amber : Colors.redAccent, size: 24),
            const SizedBox(height: 16),
            Text(label, style: TextDesign.smallText(color: theme.hint).copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
            Text(value, style: TextDesign.headingThree().copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow(AppColors theme) {
    return Row(
      children: [
        _bottomAction(Icons.home_outlined, "Home"),
        const SizedBox(width: 12),
        _bottomAction(Icons.history, "HISTORY"),
      ],
    );
  }

  Widget _bottomAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppColors theme) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.success),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: theme.success),
            const SizedBox(width: 8),
            Text("Submit Another Photo",
                style: TextStyle(color: theme.success, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}