import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String keyStation = "scanned_station";

  static Future<void> saveStation(Map<String, dynamic> station) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(keyStation, jsonEncode(station));
  }

  static Future<Map<String, dynamic>?> getStation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(keyStation);
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<void> clearStation() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(keyStation);
  }
}