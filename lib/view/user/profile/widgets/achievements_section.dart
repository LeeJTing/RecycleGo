import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Achievements.dart';

class AchievementsSection extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsSection({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    final displayAchievements = achievements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: theme.primary,
                  size: size.width * 0.06,
                ),
                const SizedBox(width: 8),
                Text(
                  'Achievements',
                  style: TextDesign.headingThree(fontSize: size.width * 0.045),
                ),
              ],
            ),
            if (achievements.length > 3)
              TextButton(
                onPressed: () => _showAllAchievements(context),
                child: Text(
                  'View All',
                  style: TextDesign.smallText(
                    color: theme.primary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: displayAchievements.map((achievement) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
              child: _buildAchievementIcon(
                achievement.label,
                _getIcon(achievement.label),
                achievement.isUnlocked,
                theme,
                size,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAllAchievements(BuildContext context) {
    final theme = AppThemes.color;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('All Achievements', style: TextDesign.headingTwo()),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return _buildAchievementIcon(
                  a.label,
                  _getIcon(a.label),
                  a.isUnlocked,
                  theme,
                  MediaQuery.of(context).size,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String label) {
    switch (label.toUpperCase()) {
      case 'FIRST RECYCLE':
        return Icons.recycling;
      case '1 WEEK STREAK':
        return Icons.flash_on;
      case '1 MONTH STREAK':
        return Icons.calendar_month;
      case '10+ STATIONS':
        return Icons.location_on;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildAchievementIcon(
    String label,
    IconData icon,
    bool isUnlocked,
    AppColors theme,
    Size size,
  ) {
    final Color iconColor = isUnlocked
        ? theme.onSuccessContainer
        : theme.onHint.withOpacity(0.3);
    final Color bgColor = isUnlocked
        ? theme.successContainer
        : theme.surfaceVariant;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: size.width * 0.08),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextDesign.badgeText(
            color: isUnlocked ? theme.onSurface : theme.onHint.withOpacity(0.5),
            fontSize: size.width * 0.022,
          ),
        ),
      ],
    );
  }
}
