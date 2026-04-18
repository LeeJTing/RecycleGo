import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Admins.dart';

class AdminCard extends StatelessWidget {
  final Admins admin;
  final AppColors theme;
  final Function(bool)? onStatusChanged;
  final bool isCurrentUser;

  const AdminCard({
    super.key,
    required this.admin,
    required this.theme,
    this.onStatusChanged,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = admin.adminStatus == 'active';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCurrentUser ? theme.primary : theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: theme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(admin.username, style: TextDesign.largeText()),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text("YOU", style: TextDesign.badgeText(color: theme.primary, fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      Text(admin.email, style: TextDesign.smallText()),
                    ],
                  ),
                ),
                _buildRoleBadge(admin.role),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      isActive ? "Active" : "Inactive",
                      style: TextDesign.smallText(
                        color: isActive ? theme.success : theme.error,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    if (!isCurrentUser)
                      Switch(
                        value: isActive,
                        onChanged: onStatusChanged,
                        activeColor: theme.primary,
                      )
                    else
                      Icon(Icons.lock_outline, size: 20, color: theme.hint),
                  ],
                ),
                if (isCurrentUser)
                  Text("Cannot modify own account", style: TextDesign.smallText(color: theme.hint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    bool isSuper = role.toLowerCase() == 'super admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuper ? theme.warningContainer : theme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSuper ? theme.warning : theme.secondary,
        ),
      ),
    );
  }
}
