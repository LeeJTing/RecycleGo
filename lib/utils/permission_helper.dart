import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, 'Camera');
    }
    return false;
  }

  static Future<bool> requestGalleryPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Requesting both handles differences across Android versions
      // API 33+ uses Permission.photos, while older versions use Permission.storage
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();

      bool granted = statuses[Permission.photos]!.isGranted || 
                     statuses[Permission.photos]!.isLimited || 
                     statuses[Permission.storage]!.isGranted;

      if (granted) return true;

      // Only show settings dialog if the relevant permission for the OS version was denied
      if (statuses[Permission.photos]!.isPermanentlyDenied || 
          statuses[Permission.storage]!.isPermanentlyDenied) {
        _showSettingsDialog(context, 'Gallery');
      }
    } else {
      // iOS logic
      PermissionStatus status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) _showSettingsDialog(context, 'Gallery');
    }
    return false;
  }

  static void _showSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'This app needs $permissionName permission to update your profile picture. '
          'Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
