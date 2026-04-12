import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/utils/hashing.dart';
import 'UserSettings.dart';

class Users {
  final String? userId;
  final String userName;
  final String email;
  final String? countryCallingCode;
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
    this.countryCallingCode,
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
      countryCallingCode: json['phone'] == null ? null : json['country_calling_code'],
      phone: json['phone'],
      profilePhoto: json['profile_photo'],
      totalPoints: json['total_points'] ?? 0,
      accountStatus: json['account_status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      hashedPassword: json['hashed_password'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_name': userName,
      'email': email,
      'country_calling_code': countryCallingCode,
      'phone': phone,
      'profile_photo': profilePhoto,
      'total_points': totalPoints,
      'account_status': accountStatus,
      'hashed_password': hashedPassword,
    };
    
    // Do NOT include user_id or created_at if they are null,
    // let the database handle default values (UUID and TIMESTAMP).
    if (userId != null) data['user_id'] = userId;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    
    return data;
  }
}

class UsersModel extends Connector {
  static final UsersModel _instance = UsersModel._internal();

  UsersModel._internal();

  factory UsersModel() => _instance;

  Future<Users?> authenticate(String email, String password) async {
    try {
      final String hashedPassword = Hashing.hashString(password);
      final response = await client
          .from('users')
          .select()
          .eq('email', email)
          .eq('hashed_password', hashedPassword)
          .maybeSingle();

      if (response != null) {
        return Users.fromJson(response);
      }
    } catch (e) {
      print('DEBUG: Users authentication error: $e');
    }
    return null;
  }

  Future<bool?> userIsActive(String email) async {
    final response = await client
        .from('users')
        .select('account_status')
        .eq('email', email)
        .maybeSingle();

    if (response != null) {
      return response['account_status'] == 'active';
    }
    return null;
  }

  Future<bool> emailIsExist(String email) async {
    final response = await client
        .from('users')
        .select('email')
        .eq('email', email);

    return response.isNotEmpty;
  }

  Future<Users?> createUser(Users user) async {
    try {
      final Map<String, dynamic> userData = user.toJson();
      if (userData['hashed_password'] != null) {
        userData['hashed_password'] = Hashing.hashString(userData['hashed_password']);
      }
      
      final response = await client
          .from('users')
          .insert(userData)
          .select()
          .single();
      
      final newUser = Users.fromJson(response);
      
      // Initialize UserSetting for the new user
      UserSettingsModel().createUserSetting(newUser.userId!);

      return newUser;
    } catch (e) {
      print('DEBUG: Create user error: $e');
      rethrow; // Rethrow to let TaskRunner show the actual error message
    }
  }
}
