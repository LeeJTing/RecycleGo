import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginCtrl ctrl = LoginCtrl();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('Login', style: TextDesign.appBarTitle()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.border.withOpacity(0.2), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),
                  
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
                  
                  // Welcome Text
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
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: ctrl.emailCtrl,
                    hintText: 'user@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: ctrl.passwordCtrl,
                    hintText: '••••••••',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextDesign.smallText(
                          color: theme.primary, 
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => ctrl.login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
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
                  
                  const SizedBox(height: 24),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextDesign.smallText(),
                      ),
                      InkWell(
                        onTap: () {
                          // Navigate to the registration screen
                          Navigator.pushNamed(context, Routes.userProfile);
                        },
                        child: Text(
                          "Sign Up",
                          style: TextDesign.smallText(
                            color: theme.primary,
                          ).copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextDesign.label(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required IconData prefixIcon,
  }) {
    final theme = AppThemes.color;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextDesign.normalText(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextDesign.hintText(),
        prefixIcon: Icon(prefixIcon, color: theme.onHint, size: 22),
        filled: true,
        fillColor: theme.border.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.border.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.onError),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
