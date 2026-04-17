import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/utils/hashing.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String currentHashedPassword;
  final Future<void> Function(String) onPasswordChanged;
  const ChangePasswordScreen({
    super.key, 
    required this.currentHashedPassword,
    required this.onPasswordChanged,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Change Password', style: TextDesign.appBarTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security', style: TextDesign.headingTwo()),
              const SizedBox(height: 8),
              Text('Verify your identity and set a new password.', style: TextDesign.smallText()),
              const SizedBox(height: 32),

              const AuthLabel(text: 'Current Password'),
              AuthTextField(
                controller: _currentPasswordController,
                hintText: '••••••••',
                obscureText: !_isCurrentPasswordVisible,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility, color: theme.onHint, size: 20),
                  onPressed: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              const Divider(height: 40),

              AuthLabel(text: 'New Password', isValid: _passwordStrength >= 3),
              AuthTextField(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: !_isPasswordVisible,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: theme.onHint, size: 20),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                onChanged: (_) => _updateStrength(),
                borderColor: _passwordController.text.isNotEmpty && _passwordStrength < 3 ? theme.error.withOpacity(0.3) : null,
                errorText: _passwordController.text.isNotEmpty && _passwordStrength < 3 
                    ? 'Should be 7-12 chars and include 3 of: Upper, Lower, Number or Special' : null,
              ),
              const SizedBox(height: 10),

              // Password Strength Bar
              Row(
                children: List.generate(4, (index) {
                  Color barColor = theme.border;
                  if (index < _passwordStrength) {
                    if (_passwordStrength <= 2) barColor = theme.warning;
                    else barColor = theme.primary;
                  }
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _passwordStrength <= 1 ? 'WEAK' : (_passwordStrength == 2 ? 'MEDIUM' : 'STRONG'),
                    style: TextDesign.smallText(
                      color: _passwordStrength <= 2 ? theme.warning : theme.primary,
                      fontSize: 10,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_passwordStrength/4',
                    style: TextDesign.smallText(color: theme.onHint, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const AuthLabel(text: 'Confirm New Password'),
              AuthTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                obscureText: !_isConfirmPasswordVisible,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility, color: theme.onHint, size: 20),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                onChanged: (_) => setState(() {}),
                errorText: _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text != _passwordController.text 
                    ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _canSave() ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    disabledBackgroundColor: theme.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Update Password', style: TextDesign.buttonText()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave() {
    if (_currentPasswordController.text.isEmpty) return false;
    if (_passwordController.text.isEmpty) return false;
    if (!Validators.isPasswordSecure(_passwordController.text)) return false;
    if (_passwordController.text != _confirmPasswordController.text) return false;
    return true;
  }

  void _save() async {
    // 1. Verify Current Password locally before running task
    final inputHashed = Hashing.hashString(_currentPasswordController.text);
    if (inputHashed != widget.currentHashedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The current password you entered is incorrect."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Run the update task
    final newHashedPassword = Hashing.hashString(_passwordController.text);
    
    await TaskRunner.run(
      context: context,
      task: () async {
        await widget.onPasswordChanged(newHashedPassword);
      },
      loadingMessage: "Updating your password...",
      successMessage: "Password updated successfully!",
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
