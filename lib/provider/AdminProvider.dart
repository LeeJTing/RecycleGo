import 'package:flutter/material.dart';
import 'package:recycle_go/models/Admins.dart';

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
}
