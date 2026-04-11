import 'package:email_otp/email_otp.dart';
import 'package:recycle_go/services/smtp_config.dart';

class OtpService {
  // Singleton instance to maintain state across screens
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  final EmailOTP _emailOTP = EmailOTP();

  /// Configures and sends a 6-digit OTP to the specified [email].
  Future<bool> sendOtp(String email) async {
    try {
      SmtpConfig.configure(_emailOTP, email);
      return await EmailOTP.sendOTP(email: 'email');
    } catch (e) {
      print('DEBUG: OtpService sendOtp error: $e');
      return false;
    }
  }

  /// Verifies the [otp] entered by the user.
  bool verifyOtp(String otp) {
    return EmailOTP.verifyOTP(otp: otp);
  }

  /// Returns the underlying EmailOTP instance if needed.
  EmailOTP get instance => _emailOTP;
}
