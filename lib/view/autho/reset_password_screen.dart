import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final LoginCtrl _loginCtrl = LoginCtrl();
  
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = Validators.isPasswordSecure(value);
      _isConfirmPasswordValid = _confirmPasswordController.text == value;
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid = value == _passwordController.text;
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
              Text('Reset Password', style: TextDesign.headingOne(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'Create a new secure password for your account.',
                style: TextDesign.smallText(color: theme.onHint),
              ),
              const SizedBox(height: 40),
              
              AuthLabel(text: 'New Password', isValid: _isPasswordValid),
              AuthTextField(
                controller: _passwordController,
                onChanged: _validatePassword,
                hintText: '••••••••',
                obscureText: _obscurePassword,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              
              const SizedBox(height: 20),
              
              AuthLabel(text: 'Confirm Password', isValid: _isConfirmPasswordValid),
              AuthTextField(
                controller: _confirmPasswordController,
                onChanged: _validateConfirmPassword,
                hintText: '••••••••',
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isPasswordValid && _isConfirmPasswordValid) ? _resetPassword : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    disabledBackgroundColor: theme.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Reset Password', style: TextDesign.buttonText(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    await _loginCtrl.resetPassword(widget.email, _passwordController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset successfully', style: TextDesign.normalText(color: Colors.white)), backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }
  }
}
