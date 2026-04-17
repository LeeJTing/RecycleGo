import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class ProfileSummary extends StatelessWidget {
  final int totalPoints;
  final int totalItems;

  const ProfileSummary({
    super.key,
    required this.totalPoints,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL POINTS',
            value: totalPoints.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
            color: theme.primary,
            size: size,
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL RECYCLE ITEM',
            value: totalItems.toString(),
            color: theme.primary,
            size: size,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Size size;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextDesign.badgeText(color: theme.onPrimary, fontSize: size.width * 0.025),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            value,
            style: TextDesign.headingOne(color: theme.onPrimary, fontSize: size.width * 0.06),
          ),
        ],
      ),
    );
  }
}
