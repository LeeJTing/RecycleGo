import 'package:recycle_go/models/Connector.dart';

class Admins {
  final String? adminId;
  final String username;
  final String email;
  final String adminStatus;
  final String role;
  final DateTime? createdAt;
  final String? hashedPassword;

  Admins({
    this.adminId,
    required this.username,
    required this.email,
    required this.adminStatus,
    required this.role,
    this.createdAt,
    this.hashedPassword,
  });

  factory Admins.fromJson(Map<String, dynamic> json) {
    return Admins(
      adminId: json['admin_id'],
      username: json['username'],
      email: json['email'],
      adminStatus: json['admin_status'],
      role: json['role'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      hashedPassword: json['hashed_password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'username': username,
      'email': email,
      'admin_status': adminStatus,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'hashed_password': hashedPassword,
    };
  }
}

class AdminsModel extends Connector {
  static final AdminsModel _instance = AdminsModel._internal();
  AdminsModel._internal();
  factory AdminsModel() => _instance;

  Future<Admins?> authenticate(String email, String password) async {
    final response = await client
        .from('admins')
        .select()
        .eq('email', email)
        .eq('hashed_password', password)
        .maybeSingle();

    if (response != null) {
      return Admins.fromJson(response);
    }
    return null;
  }

  Future<bool> emailIsExist(String email) async {
    final response = await client
        .from('admins')
        .select('email')
        .eq('email', email);

    return response.isNotEmpty;
  }
}
