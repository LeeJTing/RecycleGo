

import 'package:flutter/cupertino.dart';

class LoginCtrl {

  static final LoginCtrl _instance = LoginCtrl._internal();

  LoginCtrl._internal();

  factory LoginCtrl() => _instance;

  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();



}