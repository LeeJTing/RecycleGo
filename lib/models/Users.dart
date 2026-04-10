import 'package:recycle_go/models/Connector.dart';

class Users {
  final String? userId;
  final String userName;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final int totalPoints;
  final String accountStatus;
  final DateTime? createdAt;
  final String? hashedPassword;

  Users({
    this.userId,
    required this.userName,
    required this.email,
    this.phone,
    this.profilePhoto,
    this.totalPoints = 0,
    required this.accountStatus,
    this.createdAt,
    this.hashedPassword,
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      userId: json['user_id'],
      userName: json['user_name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profile_photo'],
      totalPoints: json['total_points'] ?? 0,
      accountStatus: json['account_status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      hashedPassword: json['hashed_password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'email': email,
      'phone': phone,
      'profile_photo': profilePhoto,
      'total_points': totalPoints,
      'account_status': accountStatus,
      'created_at': createdAt?.toIso8601String(),
      'hashed_password': hashedPassword,
    };
  }
}

class UsersModel extends Connector {
  Future<Users?> authenticate(String email, String password) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('email', email)
          .eq('hashed_password', password)
          .maybeSingle();

      if (response != null) {
        return Users.fromJson(response);
      }
    } catch (e) {
      print('DEBUG: Users authentication error: $e');
    }
    return null;
  }

  Future<Users?> getFirstUser() async {
    try {
      final response = await client
          .from('users')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return Users.fromJson(response);
      }
    } catch (e) {
      print('DEBUG: Error getting first user: $e');
    }
    return null;
  }
}
