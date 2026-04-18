import 'package:recycle_go/models/Admins.dart';

class AdminManagementCtrl {
  final _adminsModel = AdminsModel();

  Future<List<Admins>> fetchAdmins() async {
    return await _adminsModel.getAllAdmins();
  }

  Future<void> addAdmin({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final newAdmin = Admins(
      username: username,
      email: email,
      adminStatus: 'active',
      role: role,
      hashedPassword: password, // The model handles hashing if needed, or we hash here
    );
    await _adminsModel.insertAdmin(newAdmin);
  }

  Future<void> updateAdminStatus(String adminId, String status) async {
    await _adminsModel.updateStatus(adminId, status);
  }

  Future<void> updateAdminRole(String adminId, String role) async {
    await _adminsModel.updateRole(adminId, role);
  }

  Future<void> updateName(String adminId, String name) async {
    await _adminsModel.updateName(adminId, name);
  }

  Future<void> updateAdminDetails(Admins admin) async {
    await _adminsModel.updateAdmin(admin);
  }
}
