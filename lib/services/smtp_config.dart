import 'package:email_otp/email_otp.dart';

class SmtpConfig {
  /// Configures the EmailOTP static settings for our app.
  static void configure(String recipientEmail) {
    // Static configuration for the email_otp package
    EmailOTP.config(
      appName: 'RecycleGo',
      otpLength: 6,
      otpType: OTPType.numeric,
      appEmail: recipientEmail,
    );
    
    // SMTP Setup for Gmail
    // Note: 'password' must be a 16-character App Password.
    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: 'recyclegotarumt@gmail.com', 
      password: 'mbob gmud nhmi rcnf',
    );
  }
}
