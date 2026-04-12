import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService().client;

  /// Uploads an image to a specified Supabase bucket.
  /// [bucketName]: The name of the storage bucket.
  /// [path]: The destination path inside the bucket (e.g., 'profiles/user123.jpg').
  /// [file]: The File object to upload.
  Future<String?> uploadImage({
    required String bucketName,
    required String path,
    required File file,
  }) async {
    try {
      await _client.storage.from(bucketName).upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Return the public URL of the uploaded image
      return _client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      print('DEBUG: Storage upload error: $e');
      return null;
    }
  }

  /// Gets the public URL of a file in a specified bucket.
  String getPublicUrl(String bucketName, String path) {
    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  /// Deletes a file from a specified bucket.
  Future<bool> deleteImage(String bucketName, String path) async {
    try {
      await _client.storage.from(bucketName).remove([path]);
      return true;
    } catch (e) {
      print('DEBUG: Storage delete error: $e');
      return false;
    }
  }
}
