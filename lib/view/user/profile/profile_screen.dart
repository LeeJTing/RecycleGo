import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/profile/profile_ctrl.dart';
import 'package:recycle_go/models/Achievements.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/models/UserSettings.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/view/user/profile/widgets/profile_info.dart';
import 'package:recycle_go/view/user/profile/widgets/profile_summary.dart';
import 'package:recycle_go/view/user/profile/widgets/achievements_section.dart';
import 'package:recycle_go/view/user/profile/change_password_screen.dart';
import 'package:recycle_go/view/user/profile/settings_screen.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileCtrl ctrl = ProfileCtrl();

  void _navigateToEditProfile(Users user) {
    Navigator.pushNamed(
      context,
      Routes.editProfile,
      arguments: {'user': user},
    );
  }

  void _navigateToSettings(String userId) async {
    final settings = await TaskRunner.run(
      context: context,
      task: () => UserSettingsModel().getSettings(userId),
      loadingMessage: "Loading settings...",
      showSuccessDialog: false,
    );

    if (settings != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            settings: settings,
            onSettingsChanged: (newSettings) {
              // Settings are updated in DB by SettingsScreen
              setState(() {});
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Profile', style: TextDesign.appBarTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                ProfileInfo(
                  name: user.userName,
                  photoUrl: user.profilePhoto,
                  createdAt: user.createdAt,
                  email: user.email,
                  phone: user.phone,
                  countryCode: user.countryCallingCode,
                  onPickImage: (source) => ctrl.pickAndUploadImage(context, source),
                  onEditProfile: () => _navigateToEditProfile(user),
                ),
                const SizedBox(height: 32),

                FutureBuilder<Map<String, dynamic>>(
                  future: Future.wait([
                    ctrl.getTotalRecycledItems(user.userId!),
                    ctrl.getAchievements(user.userId!),
                  ]).then((results) => {
                    'totalItems': results[0] as int,
                    'achievements': results[1] as List<Achievement>,
                  }),
                  builder: (context, snapshot) {
                    final totalItems = snapshot.data?['totalItems'] ?? 0;
                    final achievements = snapshot.data?['achievements'] ?? <Achievement>[];

                    return Column(
                      children: [
                        ProfileSummary(
                          totalPoints: user.totalPoints,
                          totalItems: totalItems,
                        ),
                        const SizedBox(height: 32),
                        AchievementsSection(achievements: achievements),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                _buildMenuButton(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _navigateToSettings(user.userId!),
                  theme: theme,
                  size: size,
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen(
                          currentHashedPassword: user.hashedPassword ?? "",
                          onPasswordChanged: (hashedPassword) async {
                            await ctrl.updateProfile(
                              context,
                              user.copyWith(hashedPassword: hashedPassword)
                            );
                          },
                        ),
                      ),
                    );
                  },
                  theme: theme,
                  size: size,
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  onTap: () => ctrl.signOut(context),
                  theme: theme,
                  size: size,
                  isDestructive: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColors theme,
    required Size size,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive ? theme.error.withOpacity(0.05) : theme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? theme.error.withOpacity(0.1) : theme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? theme.error.withOpacity(0.1) : theme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDestructive ? theme.error : theme.primary, size: size.width * 0.05),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextDesign.mediumText(
                  color: isDestructive ? theme.error : theme.onSurface,
                  fontSize: size.width * 0.04,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDestructive ? theme.error.withOpacity(0.5) : theme.onHint),
          ],
        ),
      ),
    );
  }
}
