import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Token.dart';
import 'package:recycle_go/models/Users.dart';

class EmailService {
  final String _username = 'recyclegotarumt@gmail.com';
  final String _password = 'mbob gmud nhmi rcnf'; // App Password

  Future<bool> sendResetLink(String email) async {
    try {
      String? accountId;
      String accountType = 'user';
      String username = 'User';

      // Check if it's an admin first
      final admins = await AdminsModel().getAllAdmins();
      final admin = admins.cast<Admins?>().firstWhere((a) => a?.email == email, orElse: () => null);
      
      if (admin != null) {
        accountId = admin.adminId;
        accountType = 'admin';
        username = admin.username;
      } else {
        final response = await UsersModel().client.from('users').select().eq('email', email).maybeSingle();
        if (response != null) {
          final user = Users.fromJson(response);
          accountId = user.userId;
          accountType = 'user';
          username = user.userName;
        }
      }

      if (accountId == null) return false;

      return await sendAdminResetLink(email, accountId, username, accountType: accountType);
    } catch (e) {
      print("Error in sendResetLink: $e");
      return false;
    }
  }

  Future<bool> sendAdminResetLink(
    String email,
    String accountId,
    String username, {
    bool isInvite = false,
    String accountType = 'admin',
  }) async {
    try {
      final tokenModel = TokenModel();
      final token = await tokenModel.createToken(accountId, accountType);

      // Using HTTPS for deep linking with recyclego host
      final webLink = 'https://recyclego/reset-password?token=$token';
      
      final smtpServer = gmail(_username, _password);

      final String subject = isInvite ? 'Welcome to RecycleGo - Set Your Password' : 'Reset Your RecycleGo Password';
      final String actionText = isInvite ? 'set up your account' : 'reset your password';
      
      final message = Message()
        ..from = Address(_username, 'RecycleGo Admin')
        ..recipients.add(email)
        ..subject = subject
        ..html = """
          <div style="font-family: Arial, sans-serif; color: #333;">
            <h3>Hello $username,</h3>
            <p>You have been requested to $actionText for RecycleGo.</p>
            <p>Please click the button below to proceed:</p>
            <div style="margin: 20px 0;">
              <a href="$webLink" style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; font-weight: bold;">$subject</a>
            </div>
            <p>If the button doesn't work, copy and paste this link into your mobile browser:</p>
            <p style="color: #4CAF50;">$webLink</p>
            <p>This link will expire in 24 hours.</p>
            <p>Best regards,<br><strong>RecycleGo Team</strong></p>
          </div>
        """;

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
