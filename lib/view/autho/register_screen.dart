import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/autho/register_ctrl.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';
import 'package:recycle_go/view/autho/widgets/social_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterCtrl ctrl = RegisterCtrl();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailFromGoogle = false;

  // Validation States
  bool _isNameValid = false;
  bool _isEmailValid = false;
  int _passwordStrength = 0;
  bool _passwordsMatch = false;
  bool _isPhoneValid = true;
  String _selectedCountryCode = '+60';

  final List<String> _countryCodes = ['+60', '+65', '+1', '+44', '+86', '+91'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailArg = ModalRoute.of(context)?.settings.arguments as String?;
      if (emailArg != null && emailArg.isNotEmpty) {
        setState(() {
          ctrl.emailCtrl.text = emailArg;
          _isEmailFromGoogle = true;
        });
      }
      _validateFields();
    });
  }

  void _validateFields() {
    setState(() {
      _isPhoneValid = Validators.isValidPhoneNumber(ctrl.phoneCtrl.text, _selectedCountryCode);
      _isNameValid = Validators.isValidName(ctrl.nameCtrl.text);
      _isEmailValid = Validators.isValidEmail(ctrl.emailCtrl.text);
      _passwordStrength = Validators.getPasswordStrength(ctrl.passwordCtrl.text);
      _passwordsMatch = ctrl.passwordCtrl.text.isNotEmpty &&
          ctrl.passwordCtrl.text == ctrl.confirmPasswordCtrl.text;
    });
  }

  String _invalidPhoneMessage(String countryCode) {
    switch (countryCode) {
      case '+60': // Malaysia: Mobile numbers are usually 9 or 10 digits after prefix
        return 'Please enter a valid Malaysia phone number (length is 9 or 10 digits)';
      case '+65': // Singapore: 8 digits
        return 'Please enter a valid Singapore phone number (length is 8 digits)';
      case '+1':  // USA/Canada: 10 digits
        return 'Please enter a valid American or Canadian phone number (length is 10 digits)';
      case '+44': // UK: 10 digits (mobile)
        return 'Please enter a valid UK phone number (length is 10 digits)';
      case '+86': // China: 11 digits
        return 'Please enter a valid China phone number (length is 11 digits)';
      case '+91': // India: 10 digits
        return 'Please enter a valid India phone number (length is 10 digits)';
      default:
        return '';
    }
  }

  bool get _isFormValid {
    return _isNameValid &&
        _isEmailValid &&
        _passwordStrength >= 3 && 
        _passwordsMatch &&
        _agreeToTerms &&
        _isPhoneValid;
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    const String imagePath = 'assets/images/';

    return Scaffold(
      backgroundColor: theme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Image
                Image.asset(
                  '${imagePath}background_image/register_background.png',
                  width: double.infinity,
                  height: size.height * 0.35,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: size.height * 0.35,
                    color: theme.surfaceVariant,
                    child: Center(child: Icon(Icons.image, size: 50, color: theme.hint)),
                  ),
                ),
                // Leaf Icon and Title Section
                Positioned(
                  top: size.height * 0.08,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primary, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Icon(Icons.energy_savings_leaf, size: 40, color: theme.onPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create Your Account',
                        style: TextDesign.headingOne(fontSize: 26).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '"Recycle Smart. Earn Rewards."',
                        style: TextDesign.smallText(color: theme.onHint, fontSize: 13).copyWith(
                          fontStyle: FontStyle.italic, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
                // Card header overlap
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthLabel(text: 'Full Name', isValid: _isNameValid),
                  AuthTextField(
                    controller: ctrl.nameCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: 'Adam Lim',
                    prefixIcon: Icon(Icons.person_outline, color: theme.onHint, size: 20),
                    borderColor: ctrl.nameCtrl.text.isNotEmpty && !_isNameValid ? theme.error.withOpacity(0.3) : null,
                    errorText: ctrl.nameCtrl.text.isNotEmpty && !_isNameValid ? 'Only letters and spaces allowed' : null,
                  ),
                  const SizedBox(height: 16),

                  AuthLabel(text: 'Email Address', isValid: _isEmailValid),
                  AuthTextField(
                    controller: ctrl.emailCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: 'adam@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    readOnly: _isEmailFromGoogle,
                    prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                    borderColor: ctrl.emailCtrl.text.isNotEmpty && !_isEmailValid ? theme.error.withOpacity(0.3) : null,
                    errorText: ctrl.emailCtrl.text.isNotEmpty && !_isEmailValid ? 'Please enter a valid email address' : null,
                  ),
                  const SizedBox(height: 16),

                  const AuthLabel(text: 'Phone Number (Optional)'),
                  AuthTextField(
                    controller: ctrl.phoneCtrl,
                    hintText: '123456789',
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => _validateFields(),
                    prefixIcon: Container(
                      width: 80,
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              items: _countryCodes.map((String code) {
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code, style: TextDesign.normalText(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                  _validateFields();
                                });
                              },
                            ),
                          ),
                          Container(width: 1, height: 20, color: theme.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        ],
                      ),
                    ),
                    errorText: ctrl.phoneCtrl.text.isNotEmpty && !_isPhoneValid ? _invalidPhoneMessage(_selectedCountryCode) : null,
                  ),
                  const SizedBox(height: 16),

                  AuthLabel(text: 'Password', isValid: _passwordStrength >= 3),
                  AuthTextField(
                    controller: ctrl.passwordCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                    borderColor: ctrl.passwordCtrl.text.isNotEmpty && _passwordStrength < 3 ? theme.error.withOpacity(0.3) : null,
                    errorText: ctrl.passwordCtrl.text.isNotEmpty && _passwordStrength < 3
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
                        else if (_passwordStrength == 3) barColor = theme.primary;
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
                      Text('WEAK', style: TextDesign.label(fontSize: 10, color: theme.onHint)),
                      Text('SECURE', style: TextDesign.label(fontSize: 10, color: theme.onHint)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AuthLabel(text: 'Confirm Password', isValid: _passwordsMatch),
                  AuthTextField(
                    controller: ctrl.confirmPasswordCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: '••••••••',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                    borderColor: ctrl.confirmPasswordCtrl.text.isNotEmpty && !_passwordsMatch ? theme.error.withOpacity(0.4) : null,
                    errorText: ctrl.confirmPasswordCtrl.text.isNotEmpty && !_passwordsMatch ? 'Passwords must match' : null,
                  ),
                  const SizedBox(height: 16),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          activeColor: theme.primary,
                          side: BorderSide(color: theme.onHint.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() => _agreeToTerms = val ?? false);
                            _validateFields();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextDesign.smallText(fontSize: 12, color: theme.onSurface),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                              const TextSpan(text: ' and have read the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? () => ctrl.register(context, _selectedCountryCode) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        disabledBackgroundColor: theme.border,
                        disabledForegroundColor: theme.onHint,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Create Account', style: TextDesign.buttonText(fontSize: 18)),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, color: _isFormValid ? theme.onPrimary : theme.onHint),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  // OR CONTINUE WITH
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OR CONTINUE WITH', style: TextDesign.label(fontSize: 10, color: theme.onHint)),
                      ),
                      Expanded(child: Divider(color: theme.border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SocialAuthButton(
                    text: 'Google',
                    assetIcon: '${imagePath}google_logo.png',
                    onPressed: () {},
                  ),
                  
                  const SizedBox(height: 24),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: TextDesign.smallText(fontSize: 13, color: theme.onSurface)),
                      InkWell(
                        onTap: () => Navigator.pushReplacementNamed(context, Routes.login),
                        child: Text(
                          'Login here',
                          style: TextDesign.smallText(color: theme.primary, fontSize: 13).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
