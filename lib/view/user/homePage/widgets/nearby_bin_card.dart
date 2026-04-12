import 'package:flutter/material.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class NearbyBinCard extends StatelessWidget {
  const NearbyBinCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Recycle Bin',
                style: TextDesign.headingThree(fontSize: size.width * 0.045),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.map),
                child: Text(
                  'See Map',
                  style: TextDesign.smallText(color: theme.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: theme.onSuccessContainer, size: size.width * 0.045),
                    const SizedBox(width: 4),
                    Text(
                      'Green Station #42',
                      style: TextDesign.mediumText(
                        color: theme.onSuccessContainer,
                        fontSize: size.width * 0.035,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: theme.primary, size: size.width * 0.03),
                    const SizedBox(width: 4),
                    Text(
                      '80% Available',
                      style: TextDesign.smallText(color: theme.secondary, fontSize: size.width * 0.03),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Row(
            children: [
              Icon(Icons.location_on, color: theme.onHint, size: size.width * 0.04),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '245 Oak Street, North District',
                  style: TextDesign.smallText(color: theme.onHint, fontSize: size.width * 0.035),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '250m • 3 min',
                  style: TextDesign.smallText(color: theme.onSurface, fontSize: size.width * 0.03),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['PLASTIC', 'GLASS', 'PAPER'].map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  type,
                  style: TextDesign.badgeText(color: theme.onHint, fontSize: size.width * 0.025),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
