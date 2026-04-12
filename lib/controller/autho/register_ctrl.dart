import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:recycle_go/view/autho/otp_screen.dart';
import 'package:recycle_go/services/otp_service.dart';

class RegisterCtrl {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  final UsersModel _usersModel = UsersModel();
  final AdminsModel _adminsModel = AdminsModel();
  final OtpService _otpService = OtpService();

  Future<void> register(BuildContext context, String countryCode) async {
    final String name = nameCtrl.text.trim();
    final String email = emailCtrl.text.trim();
    final String password = passwordCtrl.text;
    final String phone = phoneCtrl.text.trim();

    final bool? otpSent = await TaskRunner.run<bool>(
      context: context,
      loadingMessage: "Sending verification code...",
      successMessage: "Verification code sent to $email",
      task: () async {
        // 1. Availability Checks
        if (await _usersModel.emailIsExist(email)) throw 'Email already registered as a user';
        if (await _adminsModel.emailIsExist(email)) throw 'Email already registered as an admin';

        // 2. Send OTP
        bool sent = await _otpService.sendOtp(email);
        if (!sent) throw 'Failed to send verification code. Please check your App Password and network.';
        
        return true;
      },
    );

    if (otpSent == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            onVerified: () => _finalizeRegistration(context, name, email, password, phone, countryCode),
          ),
        ),
      );
    }
  }

  Future<void> _finalizeRegistration(
    BuildContext context, 
    String name, 
    String email, 
    String password, 
    String phone, 
    String countryCode
  ) async {
    final createdUser = await TaskRunner.run<Users>(
      context: context,
      loadingMessage: "Creating your account...",
      successMessage: "Account created successfully!",
      task: () async {
        final newUserRequest = Users(
          userName: name,
          email: email,
          countryCallingCode: phone.isNotEmpty ? null : countryCode,
          phone: phone.isNotEmpty ? phone : null,
          totalPoints: 0,
          accountStatus: 'active',
          hashedPassword: password,
        );

        final user = await _usersModel.createUser(newUserRequest);
        if (user == null) throw 'Failed to create user record';
        return user;
      },
    );

    if (createdUser != null && context.mounted) {
      Provider.of<UserProvider>(context, listen: false).setUser(createdUser);
      Navigator.pushNamedAndRemoveUntil(context, Routes.userHomePage, (route) => false);
    }
  }

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
  }
}
