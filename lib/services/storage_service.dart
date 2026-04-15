import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService().client;

  /// Uploads an image to a specified Supabase bucket.
  Future<String?> uploadImage({
    required String bucketName,
    required String path,
    required File file,
  }) async {
    try {
      print('DEBUG: [StorageService] Attempting upload to bucket: "$bucketName", path: "$path"');
      // Upload the file
      final response = await _client.storage.from(bucketName).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      print('DEBUG: [StorageService] Upload successful. Supabase path returned: $response');
      return response;
    } on StorageException catch (e) {
      print('DEBUG: [StorageService] Supabase Storage Error!');
      print('DEBUG: [StorageService] Message: ${e.message}');
      print('DEBUG: [StorageService] Status Code: ${e.statusCode}');
      print('DEBUG: [StorageService] Error: ${e.error}');
      rethrow;
    } catch (e) {
      print('DEBUG: [StorageService] General Error: $e');
      rethrow;
    }
  }

  /// Generates the public URL for a file.
  String getPublicUrl(String bucketName, String path) {
    try {
      final url = _client.storage.from(bucketName).getPublicUrl(path);
      print('DEBUG: [StorageService] Generated Public URL for "$path": $url');
      return url;
    } catch (e) {
      print('DEBUG: [StorageService] Error generating Public URL: $e');
      return '';
    }
  }
}
