import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/provider/AdminProvider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

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
                const SizedBox(height: 40),
                // Admin Avatar
                CircleAvatar(
                  radius: size.width * 0.15,
                  backgroundColor: theme.primary.withOpacity(0.1),
                  child: Icon(Icons.admin_panel_settings, size: size.width * 0.15, color: theme.primary),
                ),
                const SizedBox(height: 24),
                
                // Admin Info
                Text(
                  admin.username,
                  style: TextDesign.headingOne(fontSize: size.width * 0.06),
                ),
                const SizedBox(height: 8),
                Text(
                  admin.email,
                  style: TextDesign.mediumText(color: theme.onHint),
                ),
                const SizedBox(height: 12),
                
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin.role.toUpperCase(),
                    style: TextDesign.badgeText(color: theme.onPrimary),
                  ),
                ),
                
                const SizedBox(height: 48),
                
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
