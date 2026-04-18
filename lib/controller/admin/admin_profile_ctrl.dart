import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/default_url.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/services/storage_service.dart';
import 'package:recycle_go/utils/permission_helper.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class AdminProfileCtrl {
  final AdminsModel _adminsModel = AdminsModel();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  Future<void> updateAdminProfile(BuildContext context, Admins updatedAdmin) async {
    try {
      final newAdmin = await _adminsModel.updateAdmin(updatedAdmin);
      if (context.mounted) {
        Provider.of<AdminProvider>(context, listen: false).setAdmin(newAdmin);
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
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final admin = adminProvider.admin;
    if (admin == null) return;

    final file = File(image.path);
    // Fixed naming convention: admin_UUID.exp
    final fileName = 'admin_${admin.adminId}.exp';
    final String uploadPath = DefaultUrl.adminProfileHeader + fileName;

    await TaskRunner.run(
      context: context,
      task: () async {
        final response = await _storageService.uploadImage(
          bucketName: DefaultUrl.profilesBucket,
          path: uploadPath,
          file: file,
        );

        if (response != null) {
          final updatedAdmin = admin.copyWith(profilePhoto: fileName);
          await updateAdminProfile(context, updatedAdmin);
        } else {
          throw Exception('Failed to upload image to storage');
        }
      },
      loadingMessage: "Uploading profile photo...",
      successMessage: "Profile photo updated successfully!",
    );
  }
}
