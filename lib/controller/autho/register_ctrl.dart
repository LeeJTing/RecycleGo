import 'package:flutter/material.dart';
import 'package:recycle_go/models/Users.dart';

class RegisterCtrl {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  final UsersModel _usersModel = UsersModel();

  void register(BuildContext context) {
    // Implement registration logic with Supabase
    print("Registering user...");
  }

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
  }
}
