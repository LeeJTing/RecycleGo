import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

// 1. 初始化方法（必须在 main.dart 调用）
Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(settings);
}

Future<void> showStationCreatedNotification(String name, String address) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'station_channel',
    'Station Notifications',
    channelDescription: 'Notify when station is created',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID
    'New Station Registered! 🌱',                 // Title
    'Station "$name" is now live at $address.',   // Body (这里使用了传入的参数)
    details,
  );
}

Future<void> saveFcmToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  print("FCM TOKEN => $token");

  final user = Supabase.instance.client.auth.currentUser;

  if (user != null && token != null) {
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', user.id);
  }
}