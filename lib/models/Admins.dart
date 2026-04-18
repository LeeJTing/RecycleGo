import 'package:recycle_go/models/Connector.dart';
import 'package:recycle_go/utils/hashing.dart';

class Admins {
  final String? adminId;
  final String username;
  final String email;
  final String adminStatus;
  final String role;
  final String? profilePhoto;
  final DateTime? createdAt;
  final String? hashedPassword;

  Admins({
    this.adminId,
    required this.username,
    required this.email,
    required this.adminStatus,
    required this.role,
    this.profilePhoto,
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
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      hashedPassword: json['hashed_password'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'admin_status': adminStatus,
      'role': role,
      'profile_photo': profilePhoto,
    };
    if (adminId != null) data['admin_id'] = adminId;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    if (hashedPassword != null) data['hashed_password'] = hashedPassword;
    return data;
  }

  Admins copyWith({
    String? adminId,
    String? username,
    String? email,
    String? adminStatus,
    String? role,
    String? profilePhoto,
    DateTime? createdAt,
    String? hashedPassword,
  }) {
    return Admins(
      adminId: adminId ?? this.adminId,
      username: username ?? this.username,
      email: email ?? this.email,
      adminStatus: adminStatus ?? this.adminStatus,
      role: role ?? this.role,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      hashedPassword: hashedPassword ?? this.hashedPassword,
    );
  }
}

class AdminsModel extends Connector {
  static final AdminsModel _instance = AdminsModel._internal();
  AdminsModel._internal();
  factory AdminsModel() => _instance;

  Future<Admins?> authenticate(String email, String password) async {
    final String hashedPassword = Hashing.hashString(password);
    final response = await client
        .from('admins')
        .select()
        .eq('email', email)
        .eq('hashed_password', hashedPassword)
        .maybeSingle();

    if (response != null) {
      return Admins.fromJson(response);
    }
    return null;
  }
  
  Future<void> updateName(String adminId, String name) async {
    await client
        .from('admins')
        .update({'username': name})
        .eq('admin_id', adminId);
  }

  Future<void> updateRole(String adminId, String role) async {
    await client
        .from('admins')
        .update({'role': role})
        .eq('admin_id', adminId);
  }

  Future<Admins> updateAdmin(Admins admin) async {
    final Map<String, dynamic> updateData = admin.toJson();
    
    // Ensure hashedPassword is not overwritten with null if not provided
    if (admin.hashedPassword == null) {
      updateData.remove('hashed_password');
    } else {
      updateData['hashed_password'] = Hashing.hashString(admin.hashedPassword!);
    }

    final response = await client
        .from('admins')
        .update(updateData)
        .eq('admin_id', admin.adminId!)
        .select()
        .single();
    return Admins.fromJson(response);
  }

  Future<void> updateAdminPassword(String adminId, String hashedPassword) async {
    await client
        .from('admins')
        .update({'hashed_password': hashedPassword})
        .eq('admin_id', adminId);
  }

  Future<bool?> adminIsActive(String email) async {
    final response = await client
        .from('admins')
        .select('admin_status')
        .eq('email', email)
        .maybeSingle();

    if (response != null) {
      return response['admin_status'] == 'active';
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

  Future<List<Admins>> getAllAdmins() async {
    final response = await client
        .from('admins')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Admins.fromJson(json)).toList();
  }

  Future<Admins> insertAdmin(Admins admin) async {
    final Map<String, dynamic> adminData = admin.toJson();
    if (adminData['hashed_password'] != null) {
      adminData['hashed_password'] = Hashing.hashString(adminData['hashed_password']);
    }
    
    final response = await client.from('admins').insert(adminData).select().single();
    return Admins.fromJson(response);
  }

  Future<void> updateStatus(String adminId, String status) async {
    await client
        .from('admins')
        .update({'admin_status': status})
        .eq('admin_id', adminId);
  }
}
