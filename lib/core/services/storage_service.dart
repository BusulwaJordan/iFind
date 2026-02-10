import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Upload a file to a specific bucket
  Future<String> uploadFile({
    required String bucket,
    required File file,
    required String path,
  }) async {
    try {
      final String extension = p.extension(file.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final String fullPath = '$path/$fileName';

      await _supabase.storage.from(bucket).upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return _supabase.storage.from(bucket).getPublicUrl(fullPath);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Delete a file from a bucket
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}
