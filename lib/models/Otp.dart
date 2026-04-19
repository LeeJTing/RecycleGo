import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/utils/hashing.dart';

class OtpModel extends Connector {
  static final OtpModel _instance = OtpModel._internal();
  factory OtpModel() => _instance;
  OtpModel._internal();

  Future<void> saveOtp(String email, String code) async {
    // Hash the OTP code before saving
    final String hashedCode = Hashing.hashString(code);
    
    await client.from('otp').upsert({
      'email': email,
      'code': hashedCode,
      'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 2)).toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> verifyOtp(String email, String code) async {
    try {
      // Hash the input code to compare with stored hash
      final String hashedCode = Hashing.hashString(code);

      final response = await client
          .from('otp')
          .select()
          .eq('email', email)
          .eq('code', hashedCode)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('DEBUG: OtpModel verifyOtp error: $e');
      return false;
    }
  }

  Future<void> deleteOtp(String email) async {
    await client.from('otp').delete().eq('email', email);
  }
}
