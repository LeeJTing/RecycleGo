import 'package:flutter/material.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/services/storage_service.dart';

class AdminProvider extends ChangeNotifier {
  Admins? _admin;

  Admins? get admin => _admin;

  void setAdmin(Admins admin) {
    _admin = admin;
    notifyListeners();
  }

  void clearAdmin() {
    _admin = null;
    notifyListeners();
  }

  String getProfileImageUrl() {
    if (_admin?.profilePhoto != null && _admin!.profilePhoto!.isNotEmpty) {
      return StorageService().getPublicUrl(
          DefaultUrl.profilesBucket,
          DefaultUrl.adminProfileHeader + _admin!.profilePhoto!);
    } else {
      return StorageService().getPublicUrl(
          DefaultUrl.profilesBucket, DefaultUrl.adminDefaultProfilePath);
    }
  }
}
