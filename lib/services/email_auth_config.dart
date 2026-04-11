import 'package:email_auth/email_auth.dart';

class EmailAuthConfig {
  static late EmailAuth emailAuth;

  static void initialize() {
    emailAuth = EmailAuth(sessionName: "RecycleGo");
  }
}
