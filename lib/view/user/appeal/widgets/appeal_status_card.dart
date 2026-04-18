import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Appeals.dart';
import 'package:recycle_go/view/user/appeal/appeal_list_screen.dart';
import 'package:recycle_go/view/user/appeal/appeal_detail_screen.dart';

class AppealStatusCard extends StatelessWidget {
  final List<Appeals> appeals;
  final String userId;

  const AppealStatusCard({super.key, required this.appeals, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    if (appeals.isEmpty) return const SizedBox.shrink();

    // Sort: First come last show (Newest first)
    final sortedAppeals = List<Appeals>.from(appeals)
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    final recentAppeals = sortedAppeals.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Appeals", style: TextDesign.headingThree()),
            if (appeals.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppealListScreen(initialAppeals: appeals, userId: userId),
                    ),
                  );
                },
                child: Text("View All", style: TextDesign.smallText(color: theme.primary)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentAppeals.map((appeal) => _buildAppealItem(context, appeal, theme)).toList(),
      ],
    );
  }

  Widget _buildAppealItem(BuildContext context, Appeals appeal, AppColors theme) {
    Color statusColor;
    IconData statusIcon;

    switch (appeal.appealStatus.toLowerCase()) {
      case 'approved':
        statusColor = theme.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = theme.error;
        statusIcon = Icons.highlight_off;
        break;
      default:
        statusColor = theme.warning;
        statusIcon = Icons.access_time;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppealDetailScreen(appeal: appeal)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appeal.appealReason,
                    style: TextDesign.normalText().copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    appeal.createdAt != null
                        ? "${appeal.createdAt!.day}/${appeal.createdAt!.month}/${appeal.createdAt!.year}"
                        : "Recently",
                    style: TextDesign.smallText(color: theme.hint),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
