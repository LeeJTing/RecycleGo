import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Notifications.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/storage_service.dart';

class HomeHeader extends StatefulWidget {
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.onProfileTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  int _unreadCount = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Initial load will happen in didChangeDependencies or via build check
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context).user;
    if (user?.userId != _currentUserId) {
      _currentUserId = user?.userId;
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;
    try {
      final count = await NotificationsModel().getUnreadCount(_currentUserId!);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    final user = context.watch<UserProvider>().user;

    if (user == null) return const SizedBox.shrink();

    String resolvedUrl;
    final photoUrl = user.profilePhoto;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        resolvedUrl = photoUrl;
      } else {
        resolvedUrl = StorageService().getPublicUrl(DefaultUrl.profilesBucket, DefaultUrl.userProfileHeader + photoUrl);
      }
    } else {
      resolvedUrl = StorageService().getPublicUrl(DefaultUrl.profilesBucket, DefaultUrl.userDefaultProfilePath);
    }

    // Add a timestamp to the URL to bypass image caching after an update
    final timestampedUrl = '$resolvedUrl${resolvedUrl.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}';

    return Row(
      children: [
        GestureDetector(
          onTap: widget.onProfileTap,
          child: CircleAvatar(
            radius: size.width * 0.06,
            backgroundColor: theme.surfaceVariant,
            child: ClipOval(
              child: Image.network(
                timestampedUrl,
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
                      color: theme.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image error: $error for URL: $resolvedUrl');
                  return Icon(Icons.person, color: theme.primary, size: size.width * 0.07);
                },
              ),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user.userName}!',
                style: TextDesign.headingTwo(fontSize: size.width * 0.05),
              ),
              Text(
                'Ready to recycle today?',
                style: TextDesign.smallText(color: theme.onHint, fontSize: size.width * 0.035),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_outlined, color: theme.onSurface, size: size.width * 0.07),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, Routes.userNotification);
                if (result == true) {
                  _loadUnreadCount();
                }
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.surface, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
