import 'package:recycle_go/models/Connector.dart';

class UserSettings {
  final String userId;
  final String language;
  final String themeMode;
  final bool notification;
  final bool notifyStation;
  final bool notifyAppealRequest;

  UserSettings({
    required this.userId,
    this.language = 'en',
    this.themeMode = 'light mode',
    this.notification = true,
    this.notifyStation = true,
    this.notifyAppealRequest = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'],
      language: json['language'] ?? 'en',
      themeMode: json['theme_mode'] ?? 'light mode',
      notification: json['notification'] ?? true,
      notifyStation: json['notify_station'] ?? true,
      notifyAppealRequest: json['notify_appeal_request'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language,
      'theme_mode': themeMode,
      'notification': notification,
      'notify_station': notifyStation,
      'notify_appeal_request': notifyAppealRequest,
    };
  }
}

class UserSettingsModel extends Connector {
  Future<void> createUserSetting(String userId) async {
    await client.from('usersetting').insert({
      'user_id': userId,
      'language': 'en',
      'theme_mode': 'light mode',
      'notification': true,
      'notify_station': true,
      'notify_appeal_request': true,
    });
  }
}
