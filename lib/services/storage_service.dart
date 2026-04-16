import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/services/supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService().client;
  final String _baseUrl = 'https://ngcrvuzbxzwinnzmcwxj.supabase.co';

  /// Uploads an image to a specified Supabase bucket.
  Future<String?> uploadImage({
    required String bucketName,
    required String path,
    required File file,
  }) async {
    try {
      print('DEBUG: [StorageService] Attempting upload to bucket: "$bucketName", path: "$path"');
      
      // Manually setting the base URL for the storage client to the legacy one.
      // Sometimes the dedicated storage domain causes 404 on upload as well.
      final String response = await _client.storage.from(bucketName).upload(
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
      
      // If 404, it's very likely the bucket doesn't exist.
      if (e.statusCode == '404') {
        print('DEBUG: [StorageService] Tip: Ensure bucket "$bucketName" exists and is public.');
      }
      rethrow;
    } catch (e) {
      print('DEBUG: [StorageService] General Error: $e');
      rethrow;
    }
  }

  /// Generates the public URL for a file using the manual legacy path.
  String getPublicUrl(String bucketName, String path) {
    try {
      // Construction of manual URL to match the expected legacy format.
      final String manualUrl = '$_baseUrl/storage/v1/object/public/$bucketName/$path';
      print('DEBUG: [StorageService] Generated Manual Public URL for "$path": $manualUrl');
      return manualUrl;
    } catch (e) {
      print('DEBUG: [StorageService] Error generating Public URL: $e');
      return '';
    }
  }
}
