import 'package:flutter/material.dart';
import 'package:recycle_go/models/Users.dart';

class UserProvider extends ChangeNotifier {
  Users? _user;
  int _unreadNotificationCount = 0;

  Users? get user => _user;
  int get unreadNotificationCount => _unreadNotificationCount;

  void setUser(Users user) {
    _user = user;
    notifyListeners();
  }

  void setUnreadNotificationCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void updateUserPoints(int newTotalPoints) {
    if (_user != null) {
      _user = _user!.copyWith(totalPoints: newTotalPoints);
      notifyListeners();
    }
  }
}
