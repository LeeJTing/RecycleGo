import 'package:recycle_go/models/Otp.dart';
import 'package:recycle_go/services/smtp_config.dart';
import 'package:email_otp/email_otp.dart';

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  final OtpModel _otpModel = OtpModel();

  /// Generates a 6-digit random code, saves it to Supabase, and sends it via Email.
  Future<bool> sendOtp(String email) async {
    try {
      // 1. Configure SMTP settings for EmailOTP to deliver the message
      SmtpConfig.configure(email);
      
      // 2. Trigger the package to send the email (it generates its own code)
      bool sent = await EmailOTP.sendOTP(email: email);
      
      if (sent) {
        // 3. Get the ACTUAL code that the package just generated and sent
        String? actualCode = EmailOTP.getOTP();
        
        if (actualCode != null) {
          // 4. Save that specific code to Supabase (Source of Truth)
          await _otpModel.saveOtp(email, actualCode);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('DEBUG: OtpService sendOtp error: $e');
      return false;
    }
  }

  /// Verifies the OTP against the Supabase database.
  Future<bool> verifyOtp(String email, String code) async {
    return await _otpModel.verifyOtp(email, code);
  }
}
