import 'package:flutter/material.dart';
import 'package:recycle_go/models/Users.dart';

class UserProvider extends ChangeNotifier {
  Users? _user;

  Users? get user => _user;

  void setUser(Users user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
