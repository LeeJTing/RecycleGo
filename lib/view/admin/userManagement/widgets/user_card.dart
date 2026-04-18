import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Users.dart';

class UserCard extends StatelessWidget {
  final Users user;
  final AppColors theme;
  final Function(bool)? onStatusChanged;

  const UserCard({
    super.key,
    required this.user,
    required this.theme,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = user.accountStatus == 'active';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.secondary.withOpacity(0.1),
                  child: Icon(Icons.person, color: theme.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.userName, style: TextDesign.largeText()),
                      Text(user.email, style: TextDesign.smallText()),
                    ],
                  ),
                ),
                _buildPointsBadge(user.totalPoints),
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
                    Switch(
                      value: isActive,
                      onChanged: onStatusChanged,
                      activeColor: theme.primary,
                    ),
                  ],
                ),
                Text(
                  "Joined ${user.createdAt != null ? user.createdAt!.day.toString() + '/' + user.createdAt!.month.toString() + '/' + user.createdAt!.year.toString() : 'N/A'}",
                  style: TextDesign.smallText(color: theme.hint, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, size: 14, color: theme.primary),
          const SizedBox(width: 4),
          Text(
            "$points pts",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
