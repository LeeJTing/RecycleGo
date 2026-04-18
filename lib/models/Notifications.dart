import 'package:flutter/material.dart';
import 'package:recycle_go/models/Connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Notifications {
  final String? notificationId;
  final String? userId;
  final String? adminId;
  final String whoSend;
  final String title;
  final String message;
  final String notificationStatus;
  final DateTime? createdAt;

  Notifications({
    this.notificationId,
    this.userId,
    this.adminId,
    required this.whoSend,
    required this.title,
    required this.message,
    required this.notificationStatus,
    this.createdAt,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      notificationId: json['notification_id'],
      userId: json['user_id'],
      adminId: json['admin_id'],
      whoSend: json['who_send'],
      title: json['title'],
      message: json['message'],
      notificationStatus: json['notification_status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'admin_id': adminId,
      'who_send': whoSend,
      'title': title,
      'message': message,
      'notification_status': notificationStatus,
    };
  }
}

class NotificationsModel extends Connector {
  static final NotificationsModel _instance = NotificationsModel._internal();
  NotificationsModel._internal();
  factory NotificationsModel() => _instance;

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('notification_status', 'unread');
      
      return response;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<int> getAdminUnreadCount(String adminId) async {
    try {
      final response = await client
          .from('notifications')
          .count(CountOption.exact)
          .eq('admin_id', adminId)
          .eq('notification_status', 'unread');
      
      return response;
    } catch (e) {
      debugPrint('Error fetching admin unread count: $e');
      return 0;
    }
  }

  Future<List<Notifications>> getUserNotifications(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Notifications.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching user notifications: $e');
      return [];
    }
  }

  Future<List<Notifications>> getAdminNotifications(String adminId) async {
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('admin_id', adminId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Notifications.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching admin notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'notification_status': 'read'})
          .eq('notification_id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await client
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }
}
