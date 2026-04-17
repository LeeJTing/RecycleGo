import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';
import 'package:recycle_go/view/autho/widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final LoginCtrl ctrl = LoginCtrl();
  final _formKey = GlobalKey<FormState>();
  
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    _validateFields();
    _checkRememberMe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app from the browser after Google Sign-In
    if (state == AppLifecycleState.resumed) {
      ctrl.handleAuthRedirect(context);
    }
  }

  Future<void> _checkRememberMe() async {
    await ctrl.autoLogin(context);
  }

  void _validateFields() {
    setState(() {
      _isEmailValid = Validators.isValidEmail(ctrl.emailCtrl.text);
      _isPasswordValid = ctrl.passwordCtrl.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final Size size = MediaQuery.of(context).size;
    const String imagePath = 'assets/images/';

    return Scaffold(
      backgroundColor: theme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.08),
                  
                  // Logo with circular background
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.webp', 
                      width: 80,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.recycling, 
                        size: 80, 
                        color: theme.primary
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Welcome Back!', 
                    style: TextDesign.headingOne(fontSize: 28),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Join thousands of urban residents making a difference one recycle at a time.',
                    textAlign: TextAlign.center,
                    style: TextDesign.smallText(color: theme.onHint),
                  ),
                  
                  SizedBox(height: size.height * 0.06),
                  
                  // Email Field
                  AuthLabel(text: 'Email Address', isValid: _isEmailValid),
                  AuthTextField(
                    controller: ctrl.emailCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: 'user@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  AuthLabel(text: 'Password', isValid: _isPasswordValid),
                  AuthTextField(
                    controller: ctrl.passwordCtrl,
                    onChanged: (_) => _validateFields(),
                    hintText: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: theme.onHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: theme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember Me',
                            style: TextDesign.smallText(color: theme.onSurface),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.forgotPassword);
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextDesign.smallText(color: theme.primary)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => ctrl.login(context, _rememberMe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        disabledBackgroundColor: theme.border,
                        disabledForegroundColor: theme.onHint,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextDesign.buttonText(fontSize: 18),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
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
                    onPressed: () => ctrl.signInWithGoogle(context),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextDesign.smallText(),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.register);
                        },
                        child: Text(
                          "Sign Up",
                          style: TextDesign.smallText(color: theme.primary)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
