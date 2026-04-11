import 'package:email_otp/email_otp.dart';

class SmtpConfig {
  /// Configures a specific [EmailOTP] instance for our app.
  static void configure(EmailOTP myOTP, String recipientEmail) {
    // Instance-based configuration
    myOTP.setConfig(
      appName: 'RecycleGo',
      otpLength: 6,
      otpType: OTPType.numeric,
      email: recipientEmail,
    );
    
    // SMTP Setup for Gmail
    // Note: 'password' must be a 16-character App Password.
    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: 'recyclegotarumt@gmail.com', 
      password: 'rscd jicn hcvf nqob',
    );
  }
}

extension on EmailOTP {
  void setConfig({required String appName, required int otpLength, required OTPType otpType, required String email}) {}
}
