import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
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
      // 1. Check User Account status and authenticate
      bool? isUserActive = await _usersModel.userIsActive(email);

      if (isUserActive == true) {
        final user = await _usersModel.authenticate(email, password);

        if (user != null) {
          if (context.mounted) {
            Provider.of<UserProvider>(context, listen: false).setUser(user);
            Loading.hide(context);
            Navigator.pushReplacementNamed(context, Routes.userHomePage);
          }
          return;
        }
      }

      // 2. Check Admin Account status and authenticate
      bool? isAdminActive = await _adminsModel.adminIsActive(email);
      if (isAdminActive == true) {
        final admin = await _adminsModel.authenticate(email, password);

        if (admin != null) {
          if (context.mounted) {
            Provider.of<AdminProvider>(context, listen: false).setAdmin(admin);
            Loading.hide(context);
            Navigator.pushReplacementNamed(context, Routes.adminHome);
          }
          return;
        }
      }

      // 3. Handle Inactive Accounts or Invalid Credentials
      if (context.mounted) {
        Loading.hide(context);

        // If either status is explicitly false, the account exists but is inactive
        if (isUserActive == false || isAdminActive == false) {
          _showError(context, "This account is inactive. Please contact support.");
        } else {
          _showError(context, "Email not found or password does not match");
        }
      }
    } catch (e) {
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Connection error: $e");
      }
    }
  }

  void _showError(BuildContext context, String message) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextDesign.normalText(color: theme.onError),
        ),
        backgroundColor: theme.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(size.width * 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
  }
}
