import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Achievements.dart';
import 'package:recycle_go/models/RecyclingSubmission.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/storage_service.dart';
import 'package:recycle_go/utils/permission_helper.dart';
import 'package:path/path.dart' as path;

class ProfileCtrl {
  final AchievementModel _achievementModel = AchievementModel();
  final UsersModel _usersModel = UsersModel();
  final RecyclingSubmissionModel _submissionModel = RecyclingSubmissionModel();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  Future<List<Achievement>> getAchievements(String userId) async {
    return await _achievementModel.getUserAchievements(userId);
  }

  Future<int> getTotalRecycledItems(String userId) async {
    return await _submissionModel.getTotalSubmissionsByUserId(userId);
  }

  void signOut(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).clearUser();
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  Future<void> updateProfile(BuildContext context, Users updatedUser) async {
    try {
      final newUser = await _usersModel.updateUser(updatedUser);
      Provider.of<UserProvider>(context, listen: false).setUser(newUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> pickAndUploadImage(BuildContext context, ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionHelper.requestCameraPermission(context);
    } else {
      hasPermission = await PermissionHelper.requestGalleryPermission(context);
    }

    if (!hasPermission) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Optimize image quality
      maxWidth: 512,    // Resize for profile pictures
    );
    
    if (image == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    try {
      final file = File(image.path);
      final fileExt = path.extension(image.path);
      final fileName = 'user_${user.userId}$fileExt';

      final publicUrl = await _storageService.uploadImage(
        bucketName: 'profiles',
        path: fileName,
        file: file,
      );

      if (publicUrl != null) {
        // Store only the file name in the user record
        final updatedUser = user.copyWith(profilePhoto: fileName);
        await updateProfile(context, updatedUser);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('DEBUG: Profile photo upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }
}
