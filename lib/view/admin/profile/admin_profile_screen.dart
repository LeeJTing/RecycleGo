import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/admin_profile_ctrl.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/view/admin/appealReview/appeal_review_screen.dart';
import 'package:recycle_go/view/admin/profile/edit_admin_profile_screen.dart';
import 'package:recycle_go/view/admin/profile/widgets/admin_profile_info.dart';
import 'package:recycle_go/view/user/profile/change_password_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AdminProfileCtrl _ctrl = AdminProfileCtrl();

  void _navigateToEditProfile(Admins admin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdminProfileScreen(admin: admin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Admin Profile', style: TextDesign.appBarTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final admin = adminProvider.admin;
          if (admin == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                AdminProfileInfo(
                  name: admin.username,
                  photoUrl: admin.profilePhoto,
                  createdAt: admin.createdAt,
                  email: admin.email,
                  onPickImage: (source) =>
                      _ctrl.pickAndUploadImage(context, source),
                  onEditProfile: () => _navigateToEditProfile(admin),
                ),
                const SizedBox(height: 32),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primary.withOpacity(0.5)),
                  ),
                  child: Text(
                    admin.role.toUpperCase(),
                    style: TextDesign.badgeText(color: theme.primary),
                  ),
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
                          currentHashedPassword: admin.hashedPassword ?? "",
                          onPasswordChanged: (hashedPassword) async {
                            await _ctrl.updateAdminProfile(
                              context,
                              admin.copyWith(hashedPassword: hashedPassword),
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

                // Menu Options
                _buildMenuButton(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  onTap: () => LoginCtrl().signOut(context),
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
        color: isDestructive
            ? theme.error.withOpacity(0.05)
            : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive ? theme.error.withOpacity(0.1) : theme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? theme.error.withOpacity(0.1)
                  : theme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? theme.error : theme.primary,
              size: size.width * 0.05,
            ),
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
          Icon(
            Icons.chevron_right_rounded,
            color: isDestructive ? theme.error.withOpacity(0.5) : theme.onHint,
          ),
        ],
      ),
    ),
  );
}
