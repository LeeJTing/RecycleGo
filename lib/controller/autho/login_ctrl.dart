import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/utils/loading.dart';

class LoginCtrl {
  static final LoginCtrl _instance = LoginCtrl._internal();

  LoginCtrl._internal();

  factory LoginCtrl() => _instance;

  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  final UsersModel _usersModel = UsersModel();
  final AdminsModel _adminsModel = AdminsModel();

  Future<void> login(BuildContext context) async {
    String email = emailCtrl.text.trim();
    String password = passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please fill in all fields");
      return;
    }

    Loading.show(context);

    try {
      // 1. Authenticate as User
      final user = await _usersModel.authenticate(email, password);
      
      if (user != null) {
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Loading.hide(context);
          Navigator.pushReplacementNamed(context, Routes.userHomePage);
        }
        return;
      }

      // 2. Authenticate as Admin
      final admin = await _adminsModel.authenticate(email, password);

      if (admin != null) {
        if (context.mounted) {
          Provider.of<AdminProvider>(context, listen: false).setAdmin(admin);
          Loading.hide(context);
          Navigator.pushReplacementNamed(context, Routes.adminHome);
        }
        return;
      }

      // 3. No match found
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Email not found or password does not match");
      }
    } catch (e) {
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Connection error: $e");
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
  }
}
