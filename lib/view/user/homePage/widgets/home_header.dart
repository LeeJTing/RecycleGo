import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/services/storage_service.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    required this.name,
    this.photoUrl,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    // Resolve URL: If it's just a file name, get the public URL from Supabase
    String resolvedUrl;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      resolvedUrl = StorageService().getPublicUrl(DefaultUrl.profilesBucket, DefaultUrl.userProfileHeader + photoUrl!);
    } else {
      resolvedUrl = StorageService().getPublicUrl(DefaultUrl.profilesBucket, DefaultUrl.userDefaultProfilePath);
    }

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextDesign.smallText(color: theme.onHint),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextDesign.headingTwo(fontSize: size.width * 0.05),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            children: [
              CircleAvatar(
                radius: size.width * 0.06,
                backgroundColor: theme.surfaceVariant,
                child: ClipOval(
                  child: Image.network(
                    resolvedUrl,
                    width: size.width * 0.12,
                    height: size.width * 0.12,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: theme.primary),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
