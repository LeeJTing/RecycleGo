import 'package:flutter/material.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';
import 'package:recycle_go/view/admin/profile/admin_profile_screen.dart';

class MoreScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const MoreScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        _tile(
          context,
          icon: Icons.confirmation_number_outlined,
          title: "Voucher Management",
          onTap: () => onNavigate(4),
        ),

        _tile(
          context,
          icon: Icons.list_alt_outlined,
          title: "Station Registry",
          onTap: () => onNavigate(5),
        ),

        _tile(
          context,
          icon: Icons.person_outline,
          title: "Profile",
          onTap: () => onNavigate(6),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}