import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/autho/login_ctrl.dart';
import 'package:recycle_go/view/autho/widgets/formFeildWidget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LoginCtrl();
    AppColors theme = AppThemes.color;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Login', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: Center(
        child: ListView(
          children:
          [
            SizedBox(height: size.height * 0.1),
            Column(
              mainAxisAlignment: .start,
              children: [
                Image.asset('assets/images/logo.webp', width: 80),
                const SizedBox(height: 20),
                Text('Welcome Back!', style: TextDesign.headingOne()),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: size.width * 0.15,
                  ),
                  child: Text(
                    'Join thousands of urban residents making a difference one recycle at a time.',
                    textAlign: .center,
                    style: TextDesign.smallText(color: theme.onHint),
                  ),
                ),
                const SizedBox(height: 20),
                InputField(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                InputField(
                  labelText: 'Password',
                  hintText: 'abc@123',
                  obscureText: true,
                ),
                const SizedBox(height: 5),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                  child:
                  InkWell(
                    onTap: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextDesign.smallText(color: theme.primary).copyWith(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: theme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.35,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextDesign.normalText(color: theme.onPrimary),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.1),
          ],
        ),
      ),
    );
  }
}
