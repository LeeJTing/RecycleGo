import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/services/storage_service.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const HomeHeader({super.key, required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    // Resolve URL: If it's just a file name, get the public URL from Supabase
    String? resolvedUrl = photoUrl;
    if (photoUrl != null && photoUrl!.isNotEmpty && !photoUrl!.startsWith('http')) {
      resolvedUrl = StorageService().getPublicUrl('profiles', photoUrl!);
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
        Stack(
          children: [
            CircleAvatar(
              radius: size.width * 0.06,
              backgroundColor: theme.surfaceVariant,
              backgroundImage: resolvedUrl != null && resolvedUrl.isNotEmpty ? NetworkImage(resolvedUrl) : null,
              child: resolvedUrl == null || resolvedUrl.isEmpty
                  ? Icon(Icons.person, size: size.width * 0.06, color: theme.hint)
                  : null,
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
      ],
    );
  }
}
