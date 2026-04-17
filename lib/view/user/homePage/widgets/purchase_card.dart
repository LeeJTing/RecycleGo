import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';

class PurchaseCard extends StatelessWidget {
  const PurchaseCard({super.key});

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
                'Purchase Items',
                style: TextDesign.headingThree(fontSize: size.width * 0.045),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.userPurchase),
                child: Text(
                  'Browse',
                  style: TextDesign.smallText(color: theme.primary)
                      .copyWith(fontWeight: FontWeight.bold),
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
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: theme.primary, size: size.width * 0.045),
                    const SizedBox(width: 4),
                    Text(
                      'Exclusive Deals',
                      style: TextDesign.mediumText(
                        color: theme.primary,
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
                    Icon(Icons.star, color: theme.primary, size: size.width * 0.03),
                    const SizedBox(width: 4),
                    Text(
                      '10+ Available',
                      style: TextDesign.smallText(
                          color: theme.secondary, fontSize: size.width * 0.03),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Row(
            children: [
              Icon(Icons.local_offer, color: theme.onHint, size: size.width * 0.04),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Redeem your points for amazing products',
                  style: TextDesign.smallText(
                      color: theme.onHint, fontSize: size.width * 0.035),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['FOOD', 'SHOPPING', 'LIFESTYLE'].map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  category,
                  style: TextDesign.badgeText(
                      color: theme.onHint, fontSize: size.width * 0.025),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
