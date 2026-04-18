import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Token.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/utils/hashing.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? email;

  const ResetPasswordScreen({super.key, this.token, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  int _passwordStrength = 0;

  Token? _verifiedToken;
  String? _accountId;
  String? _accountType;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _verifyToken();
    } else if (widget.email != null) {
      _resolveAccountByEmail();
    }
  }

  Future<void> _verifyToken() async {
    setState(() => _isVerifying = true);
    try {
      final tokenModel = TokenModel();
      final tokenData = await tokenModel.verifyToken(widget.token!);
      
      if (mounted) {
        setState(() {
          _verifiedToken = tokenData;
          if (tokenData != null) {
            _accountId = tokenData.accountId;
            _accountType = tokenData.accountType;
          }
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resolveAccountByEmail() async {
    setState(() => _isVerifying = true);
    try {
      // Check admin first
      final admins = await AdminsModel().getAllAdmins();
      final admin = admins.cast<Admins?>().firstWhere((a) => a?.email == widget.email, orElse: () => null);
      
      if (admin != null) {
        _accountId = admin.adminId;
        _accountType = 'admin';
      } else {
        final response = await UsersModel().client.from('users').select().eq('email', widget.email!).maybeSingle();
        if (response != null) {
          final user = Users.fromJson(response);
          _accountId = user.userId;
          _accountType = 'user';
        }
      }
      
      if (mounted) setState(() => _isVerifying = false);
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _validateFields() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
      _isPasswordValid = _passwordStrength >= 3;
      _isConfirmPasswordValid = _passwordController.text.isNotEmpty && 
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> _resetPassword() async {
    _validateFields();
    if (!_isPasswordValid || !_isConfirmPasswordValid || _accountId == null) return;

    setState(() => _isLoading = true);
    try {
      final hashedPassword = Hashing.hashString(_passwordController.text.trim());
      
      if (_accountType == 'admin') {
        final adminModel = AdminsModel();
        await adminModel.updateAdminPassword(_accountId!, hashedPassword);
      } else {
        final userModel = UsersModel();
        await userModel.updateUserPassword(_accountId!, hashedPassword);
      }

      if (widget.token != null) {
        final tokenModel = TokenModel();
        await tokenModel.markAsUsed(widget.token!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! Please login.')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    if (_isVerifying) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_accountId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Reset Password")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Account not found or link expired.", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text("New Password", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set New Password', style: TextDesign.headingTwo()),
            const SizedBox(height: 8),
            Text('Create a strong password to protect your account.', style: TextDesign.smallText()),
            const SizedBox(height: 32),

            AuthLabel(text: 'Password', isValid: _passwordStrength >= 3),
            AuthTextField(
              controller: _passwordController,
              onChanged: (_) => _validateFields(),
              hintText: '••••••••',
              obscureText: _obscurePassword,
              prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
              borderColor: _passwordController.text.isNotEmpty && _passwordStrength < 3 ? theme.error.withOpacity(0.3) : null,
              errorText: _passwordController.text.isNotEmpty && _passwordStrength < 3
                  ? 'should 7-12 chars and include either 3 of them Upper, Lower, Number or Special'
                  : null,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: theme.onHint, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
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
                Text('WEAK', style: TextDesign.smallText(color: _passwordStrength > 0 && _passwordStrength <= 2 ? theme.warning : theme.hint, fontSize: 10)),
                Text('FAIR', style: TextDesign.smallText(color: _passwordStrength == 3 ? theme.primary : theme.hint, fontSize: 10)),
                Text('STRONG', style: TextDesign.smallText(color: _passwordStrength == 4 ? theme.primary : theme.hint, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 20),

            AuthLabel(text: 'Confirm Password', isValid: _isConfirmPasswordValid),
            AuthTextField(
              controller: _confirmPasswordController,
              onChanged: (_) => _validateFields(),
              hintText: 'Confirm new password',
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
              borderColor: _confirmPasswordController.text.isNotEmpty && !_isConfirmPasswordValid ? theme.error.withOpacity(0.3) : null,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: theme.onHint, size: 20),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isPasswordValid || !_isConfirmPasswordValid) ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: theme.border,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("Reset Password", style: TextDesign.buttonText(color: theme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
