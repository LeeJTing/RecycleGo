import 'package:flutter/material.dart';
import 'package:recycle_go/models/Notifications.dart';

class NotificationService {
  final NotificationsModel _model = NotificationsModel();

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
