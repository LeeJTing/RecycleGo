import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class ScoreCards extends StatelessWidget {
  final int totalPoints;
  final int streakCount;

  const ScoreCards({super.key, required this.totalPoints, this.streakCount = 0});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            value: totalPoints.toString(),
            label: 'My Points',
            color: theme.warning,
            icon: Icons.point_of_sale,
            size: size,
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: _InfoCard(
            value: streakCount.toString(),
            label: 'Streak',
            color: theme.primary,
            icon: Icons.local_fire_department,
            size: size,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final Size size;

  const _InfoCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.02, horizontal: size.width * 0.02),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: size.width * 0.07),
          SizedBox(height: size.height * 0.01),
          Text(
            value,
            style: TextDesign.headingOne(color: color, fontSize: size.width * 0.05),
          ),
          Text(
            label,
            style: TextDesign.smallText(color: theme.onHint, fontSize: size.width * 0.03),
          ),
        ],
      ),
    );
  }
}
