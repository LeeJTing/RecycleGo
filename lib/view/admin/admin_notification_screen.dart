import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Notifications.dart';
import 'package:recycle_go/provider/AdminProvider.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  List<Notifications> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final adminId = adminProvider.admin?.adminId;
    
    if (adminId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final notifications = await NotificationsModel().getAdminNotifications(adminId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(Notifications notification) async {
    if (notification.notificationStatus == 'unread') {
      await NotificationsModel().markAsRead(notification.notificationId!);
      setState(() {
         int index = _notifications.indexWhere((n) => n.notificationId == notification.notificationId);
         if (index != -1) {
           _notifications[index] = Notifications(
             notificationId: notification.notificationId,
             userId: notification.userId,
             adminId: notification.adminId,
             whoSend: notification.whoSend,
             title: notification.title,
             message: notification.message,
             notificationStatus: 'read',
             createdAt: notification.createdAt,
           );
         }
      });
    }
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(notification.title, style: TextDesign.headingThree()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sent by: ${notification.whoSend}',
                style: TextDesign.smallText(color: AppThemes.color.primary).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                notification.createdAt != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt!)
                    : 'Recently',
                style: TextDesign.smallText(color: AppThemes.color.hint),
              ),
              const SizedBox(height: 16),
              Text(notification.message, style: TextDesign.normalText()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: AppThemes.color.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await NotificationsModel().deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => n.notificationId == id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete notification")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final unreadCount = _notifications.where((n) => n.notificationStatus == 'unread').length;
    final hasRead = _notifications.any((n) => n.notificationStatus == 'read');

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text("Admin Notifications", style: TextDesign.appBarTitle()),
            if (unreadCount > 0)
              Text(
                "$unreadCount Unread",
                style: TextDesign.label(color: theme.primary, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          if (hasRead)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.error),
              tooltip: "Delete Read",
              onPressed: () => _confirmDeleteRead(),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: theme.error),
              tooltip: "Clear All",
              onPressed: () => _confirmClearAll(),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: theme.primary,
              child: _notifications.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification, theme);
                      },
                    ),
            ),
    );
  }

  void _confirmDeleteRead() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Read Notifications?"),
        content: const Text("This will remove all notifications that you have already viewed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final readNotifications = _notifications.where((n) => n.notificationStatus == 'read').toList();
              for (var n in readNotifications) {
                await _deleteNotification(n.notificationId!);
              }
            },
            child: Text("Delete Read", style: TextStyle(color: AppThemes.color.error)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Notifications?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (var n in List.from(_notifications)) {
                await _deleteNotification(n.notificationId!);
              }
            },
            child: Text("Clear All", style: TextStyle(color: AppThemes.color.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors theme) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.notifications_off_outlined, size: 80, color: theme.hint.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "No admin alerts",
                style: TextDesign.largeText(color: theme.hint),
              ),
              Text(
                "System updates and user appeals will appear here.",
                style: TextDesign.smallText(color: theme.hint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(Notifications notification, AppColors theme) {
    final isUnread = notification.notificationStatus == 'unread';

    return Dismissible(
      key: Key(notification.notificationId!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification.notificationId!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: isUnread ? theme.primary.withOpacity(0.08) : theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnread ? theme.primary.withOpacity(0.5) : theme.border,
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () => _markAsRead(notification),
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isUnread ? theme.primary : theme.hint).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnread ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
              color: isUnread ? theme.primary : theme.onHint,
              size: 24,
            ),
          ),
          title: Text(
            notification.title,
            style: TextDesign.mediumText().copyWith(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
              color: isUnread ? theme.onSurface : theme.onSurface.withOpacity(0.7),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextDesign.smallText(color: theme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By: ${notification.whoSend}',
                    style: TextDesign.label(fontSize: 10, color: theme.primary),
                  ),
                  Text(
                    notification.createdAt != null
                        ? DateFormat('dd MMM, HH:mm').format(notification.createdAt!)
                        : 'N/A',
                    style: TextDesign.label(fontSize: 10, color: theme.hint),
                  ),
                ],
              ),
            ],
          ),
          trailing: isUnread
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
