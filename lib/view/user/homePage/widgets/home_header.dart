import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/services/storage_service.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const HomeHeader({super.key, required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name! 👋',
                style: TextDesign.headingOne(fontSize: size.width * 0.07),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to make an impact today?',
                style: TextDesign.normalText(color: theme.onHint, fontSize: size.width * 0.04),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.successContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: theme.onSuccessContainer, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Eco Expert',
                      style: TextDesign.mediumText(
                        color: theme.onSuccessContainer,
                        fontSize: size.width * 0.035,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top 5%',
                      style: TextDesign.smallText(color: theme.onHint, fontSize: size.width * 0.03),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: size.width * 0.07,
          backgroundColor: theme.surfaceVariant,
          backgroundImage: NetworkImage(StorageService.url + (photoUrl ?? DefaultUrl.defaultProfileURL)),
          child: photoUrl == null ? Icon(Icons.person, size: size.width * 0.08, color: theme.hint) : null,
        ),
      ],
    );
  }
}
