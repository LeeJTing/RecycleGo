import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/utils/hashing.dart';

class UserManagementCtrl {
  final _usersModel = UsersModel();

  Future<List<Users>> fetchUsers() async {
    // We need a method in UsersModel to fetch all users.
    // I will check UsersModel first.
    return await _usersModel.getAllUsers();
  }

  Future<void> addUser({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    final newUser = Users(
      userName: username,
      email: email,
      accountStatus: 'active',
      hashedPassword: password, // UsersModel.createUser handles hashing
      phone: phone,
      totalPoints: 0,
    );
    await _usersModel.createUser(newUser);
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final user = Users(
      userId: userId,
      userName: '', // Not used for partial update in this simplified logic, 
                    // but we should probably fetch first or update via Map
      email: '',
      accountStatus: status,
    );
    // Ideally we have a more specific update method or just use the existing one
    // Let's assume we use a Map based update for flexibility if available
    await _usersModel.updateUserStatus(userId, status);
  }

  Future<void> updateUserDetails(Users user) async {
    await _usersModel.updateUser(user);
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    final hashedPassword = Hashing.hashString(newPassword);
    await _usersModel.updateUserPassword(userId, hashedPassword);
  }
}
