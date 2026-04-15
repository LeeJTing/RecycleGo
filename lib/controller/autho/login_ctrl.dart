import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/otp_service.dart';
import 'package:recycle_go/utils/hashing.dart';
import 'package:recycle_go/utils/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginCtrl {
  static final LoginCtrl _instance = LoginCtrl._internal();

  LoginCtrl._internal();

  factory LoginCtrl() => _instance;

  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  final UsersModel _usersModel = UsersModel();
  final AdminsModel _adminsModel = AdminsModel();
  final OtpService _otpService = OtpService();

  static const String _keyEmail = 'remember_email';
  static const String _keyPassword = 'remember_password';
  static const String _keyType = 'remember_type';

  Future<void> autoLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);
    final type = prefs.getString(_keyType);

    if (email != null && password != null && type != null) {
      emailCtrl.text = email;
      passwordCtrl.text = password;
      await login(context, true);
    }
  }

  Future<void> login(BuildContext context, bool rememberMe) async {
    String email = emailCtrl.text.trim();
    String password = passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please fill in all fields");
      return;
    }

    Loading.show(context);

    try {
      // 1. Check User Account
      bool? isUserActive = await _usersModel.userIsActive(email);
      if (isUserActive == true) {
        final user = await _usersModel.authenticate(email, password);
        if (user != null) {
          if (rememberMe) await _saveCredentials(email, password, 'user');
          if (context.mounted) {
            Provider.of<UserProvider>(context, listen: false).setUser(user);
            Loading.hide(context);
            Navigator.pushReplacementNamed(context, Routes.userHomePage);
          }
          return;
        }
      }

      // 2. Check Admin Account
      bool? isAdminActive = await _adminsModel.adminIsActive(email);
      if (isAdminActive == true) {
        final admin = await _adminsModel.authenticate(email, password);
        if (admin != null) {
          if (rememberMe) await _saveCredentials(email, password, 'admin');
          if (context.mounted) {
            Provider.of<AdminProvider>(context, listen: false).setAdmin(admin);
            Loading.hide(context);
            Navigator.pushReplacementNamed(context, Routes.adminHome);
          }
          return;
        }
      }

      if (context.mounted) {
        Loading.hide(context);
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

  Future<void> signInWithGoogle(BuildContext context) async {
    Loading.show(context);
    try {
      final supabase = Supabase.instance.client;
      
      // Attempt Google Sign In
      // Note: This requires Google Auth to be enabled in Supabase Dashboard
      // and potentially additional platform-specific configuration (OAuth 2.0 Client IDs)
      final bool success = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.recyclego://login-callback', // Replace with your deep link
      );

      if (!success) {
        if (context.mounted) {
          Loading.hide(context);
          _showError(context, "Google Sign In failed to initialize");
        }
        return;
      }

      // After redirect back to the app, we need to check if the user exists in our DB
      // Note: In a real app, you'd listen to auth state changes.
      // For this implementation, we'll assume the user is returned after OAuth.
      
      final session = supabase.auth.currentSession;
      if (session == null || session.user == null) {
        // Handled by the redirect/auth state listener in most cases
        return;
      }

      final String email = session.user!.email!;
      
      // Check if user exists in our 'Users' table
      bool exists = await _usersModel.emailIsExist(email);
      
      if (context.mounted) {
        Loading.hide(context);
        if (exists) {
          // Fetch the full user model
          final response = await _usersModel.client
              .from('users')
              .select()
              .eq('email', email)
              .single();
          
          final user = Users.fromJson(response);
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.pushReplacementNamed(context, Routes.userHomePage);
        } else {
          // Redirect to register with email pre-filled
          Navigator.pushNamed(context, Routes.register, arguments: email);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Google Sign In Error: $e");
      }
    }
  }

  Future<void> _saveCredentials(String email, String password, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyType, type);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyType);
  }

  void signOut(BuildContext context) async {
    await clearCredentials();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Provider.of<AdminProvider>(context, listen: false).clearAdmin();
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    bool userExists = await _usersModel.emailIsExist(email);
    bool adminExists = await _adminsModel.emailIsExist(email);
    return userExists || adminExists;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final String hashedPassword = Hashing.hashString(newPassword);
    
    // Attempt to update user
    bool userExists = await _usersModel.emailIsExist(email);
    if (userExists) {
      await _usersModel.client
          .from('users')
          .update({'hashed_password': hashedPassword})
          .eq('email', email);
      return;
    }

    // Attempt to update admin
    bool adminExists = await _adminsModel.emailIsExist(email);
    if (adminExists) {
      await _adminsModel.client
          .from('admins')
          .update({'hashed_password': hashedPassword})
          .eq('email', email);
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
