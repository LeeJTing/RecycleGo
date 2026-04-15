import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';
import 'package:recycle_go/view/autho/otp_screen.dart';
import 'package:recycle_go/view/autho/reset_password_screen.dart';
import 'package:recycle_go/services/otp_service.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final LoginCtrl _loginCtrl = LoginCtrl();
  final OtpService _otpService = OtpService();
  bool _isEmailValid = false;

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = Validators.isValidEmail(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Forgot Password', style: TextDesign.headingOne(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'Enter your email address to receive a 6-digit verification code.',
                style: TextDesign.smallText(color: theme.onHint),
              ),
              const SizedBox(height: 40),
              AuthLabel(text: 'Email Address', isValid: _isEmailValid),
              AuthTextField(
                controller: _emailController,
                onChanged: _validateEmail,
                hintText: 'user@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isEmailValid ? _sendOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    disabledBackgroundColor: theme.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Send Code', style: TextDesign.buttonText(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    
    // First, check if email exists in DB
    final exists = await _loginCtrl.checkEmailExists(email);
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email not found', style: TextDesign.normalText(color: Colors.white)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Use TaskRunner to send OTP
    final sent = await TaskRunner.run<bool>(
      context: context,
      loadingMessage: "Sending verification code...",
      successMessage: "Verification code sent to $email",
      task: () => _otpService.sendOtp(email),
    );

    if (sent == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            isRegistering: false,
            onVerified: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(email: email),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
