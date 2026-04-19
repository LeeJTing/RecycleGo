import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:recycle_go/models/Notifications.dart';

class NotificationService {
  final NotificationsModel _model = NotificationsModel();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize local notifications for the device
  Future<void> initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click here if needed
      },
    );

    // Create a high importance channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Show a system notification on the device tray
  Future<void> showSystemNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      notificationDetails,
    );
  }

  /// Sends a notification to a specific user from an admin
  Future<void> sendToUser({
    required String userId,
    required String adminId,
    required String title,
    required String message,
  }) async {
    final notification = Notifications(
      userId: userId,
      adminId: adminId,
      whoSend: 'admin',
      title: title,
      message: message,
      notificationStatus: 'unread',
    );
    await _model.insertNotification(notification);
  }

  /// Sends a notification to a specific admin from a user
  Future<void> sendToAdmin({
    required String adminId,
    required String userId,
    required String title,
    required String message,
  }) async {
    final notification = Notifications(
      adminId: adminId,
      userId: userId,
      whoSend: 'user',
      title: title,
      message: message,
      notificationStatus: 'unread',
    );
    await _model.insertNotification(notification);
  }

  /// Broadcasts a message to multiple users
  Future<void> broadcastToUsers({
    required List<String> userIds,
    required String adminId,
    required String title,
    required String message,
  }) async {
    for (String id in userIds) {
      await sendToUser(
        userId: id,
        adminId: adminId,
        title: title,
        message: message,
      );
    }
  }

  /// Convenience method for common appeal updates
  Future<void> notifyAppealUpdate({
    required String userId,
    required String adminId,
    required String status,
    double? points,
  }) async {
    final title = "Appeal ${status[0].toUpperCase()}${status.substring(1)}";
    final message = status.toLowerCase() == 'approved'
        ? "Your appeal has been approved! You've been awarded ${points?.toInt() ?? 0} points."
        : "Your appeal has been rejected. Please check the appeal details for more info.";

    await sendToUser(
      userId: userId,
      adminId: adminId,
      title: title,
      message: message,
    );
  }
}
