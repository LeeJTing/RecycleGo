import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/models/Achievements.dart';
import 'package:recycle_go/models/RecyclingSubmission.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/storage_service.dart';
import 'package:recycle_go/utils/permission_helper.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:path/path.dart' as path;
import 'package:recycle_go/controller/autho/login_ctrl.dart';

class ProfileCtrl {
  final AchievementModel _achievementModel = AchievementModel();
  final UsersModel _usersModel = UsersModel();
  final RecycleSubmissionModel _submissionModel = RecycleSubmissionModel();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  Future<List<Achievement>> getAchievements(String userId) async {
    return await _achievementModel.getUserAchievements(userId);
  }

  Future<int> getTotalRecycledItems(String userId) async {
    return await _submissionModel.getTotalItemsByUserId(userId);
  }

  void signOut(BuildContext context) {
    LoginCtrl().signOut(context);
  }

  Future<void> updateProfile(BuildContext context, Users updatedUser) async {
    try {
      final newUser = await _usersModel.updateUser(updatedUser);
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(newUser);
      }
    } catch (e) {
      rethrow;
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
      imageQuality: 70,
      maxWidth: 512,
    );
    
    if (image == null) return;

    if (!context.mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;

    final file = File(image.path);
    final fileExt = path.extension(image.path);
    final fileName = 'user_${user.userId}$fileExt';
    final String uploadPath = DefaultUrl.userProfileHeader + fileName;

    await TaskRunner.run(
      context: context,
      task: () async {
        final response = await _storageService.uploadImage(
          bucketName: DefaultUrl.profilesBucket,
          path: uploadPath,
          file: file,
        );

        if (response != null) {
          final updatedUser = user.copyWith(profilePhoto: fileName);
          await updateProfile(context, updatedUser);
        } else {
          throw Exception('Failed to upload image to storage');
        }
      },
      loadingMessage: "Uploading profile photo...",
      successMessage: "Profile photo updated successfully!",
    );
  }
}
