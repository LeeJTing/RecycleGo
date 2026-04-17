import 'package:flutter/foundation.dart';
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
      // 1. Check if it's a User account
      bool? isUserActive = await _usersModel.userIsActive(email);
      if (isUserActive != null) { // User exists
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
          } else {
            // Found user but password failed
            if (context.mounted) {
              Loading.hide(context);
              _showError(context, "Incorrect password for your user account.");
            }
            return;
          }
        } else {
          // User exists but is inactive
          if (context.mounted) {
            Loading.hide(context);
            _showError(context, "This user account is inactive. Please contact support.");
          }
          return;
        }
      }

      // 2. Check if it's an Admin account
      bool? isAdminActive = await _adminsModel.adminIsActive(email);
      if (isAdminActive != null) { // Admin exists
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
          } else {
            // Found admin but password failed
            if (context.mounted) {
              Loading.hide(context);
              _showError(context, "Incorrect password for your admin account.");
            }
            return;
          }
        } else {
          // Admin exists but is inactive
          if (context.mounted) {
            Loading.hide(context);
            _showError(context, "This admin account is inactive. Please contact support.");
          }
          return;
        }
      }

      // 3. Email not found in either table
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "This email is not registered in our system.");
      }
    } catch (e) {
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Connection error: $e");
      }
    }
  }

  /// Starts the Google Sign-In process.
  /// Important: You MUST add 'io.supabase.recyclego://login-callback' 
  /// to Supabase Dashboard -> Auth -> Redirect URLs.
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;

      // On mobile, this opens the browser.
      // Execution in this method will NOT wait for the user to return.
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.recyclego://login-callback',
      );
      
      // Note: We don't hide loading here because the browser is opening.
      // The actual login check happens in handleAuthRedirect.
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Google Sign In Error: $e");
      }
    }
  }

  /// This should be called when the app returns from the Google Sign-In redirect.
  /// It checks if the user exists in our DB and handles navigation.
  Future<void> handleAuthRedirect(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    
    if (session == null || session.user == null) return;

    final String email = session.user!.email!;
    Loading.show(context);

    try {
      bool exists = await _usersModel.emailIsExist(email);
      
      if (context.mounted) {
        Loading.hide(context);
        if (exists) {
          final response = await _usersModel.client
              .from('users')
              .select()
              .eq('email', email)
              .single();
          
          final user = Users.fromJson(response);
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.pushReplacementNamed(context, Routes.userHomePage);
        } else {
          // If the user doesn't exist in our table, sign them out from Supabase Auth
          // so they don't stay "logged in" with a partial account.
          await supabase.auth.signOut();
          Navigator.pushNamed(context, Routes.register, arguments: email);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Loading.hide(context);
        _showError(context, "Redirect Handling Error: $e");
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
