import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors theme = AppThemes.color;

    return Scaffold(
      appBar: AppBar(centerTitle: true,
        title: Text('Login', style: TextDesign.normalText()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .start,
          children: [
            Image.asset(
                'assets/images/logo.webp',
                width: 80
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome Back!',
              style: TextDesign.headingOne(),
            ),
            const SizedBox(height: 20,),

          ],
        ),
      ),
    );
  }
}
