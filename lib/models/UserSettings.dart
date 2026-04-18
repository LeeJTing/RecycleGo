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

  UserSettings copyWith({
    String? language,
    String? themeMode,
    bool? notification,
    bool? notifyStation,
    bool? notifyAppealRequest,
  }) {
    return UserSettings(
      userId: userId,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      notification: notification ?? this.notification,
      notifyStation: notifyStation ?? this.notifyStation,
      notifyAppealRequest: notifyAppealRequest ?? this.notifyAppealRequest,
    );
  }
}

class UserSettingsModel extends Connector {
  static final UserSettingsModel _instance = UserSettingsModel._internal();
  UserSettingsModel._internal();
  factory UserSettingsModel() => _instance;

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

  Future<UserSettings?> getSettings(String userId) async {
    final response = await client
        .from('usersetting')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return UserSettings.fromJson(response);
    }
    return null;
  }

  Future<void> updateSettings(UserSettings settings) async {
    await client
        .from('usersetting')
        .update(settings.toJson())
        .eq('user_id', settings.userId);
  }
}
