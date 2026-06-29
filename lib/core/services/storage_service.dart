import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Upload an XFile (from image_picker) — works on web and mobile.
  Future<String> uploadXFile({
    required String bucket,
    required XFile xFile,
    required String path,
  }) async {
    try {
      final String ext = kIsWeb
          ? (xFile.mimeType?.split('/').last ?? 'jpg')
          : p.extension(xFile.path).replaceFirst('.', '');
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final String fullPath = '$path/$fileName';
      final Uint8List bytes = await xFile.readAsBytes();

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: xFile.mimeType ?? 'image/jpeg',
            ),
          );

      return _supabase.storage.from(bucket).getPublicUrl(fullPath);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Upload a dart:io File — used by product uploads (native only).
  Future<String> uploadFile({
    required String bucket,
    required File file,
    required String path,
  }) async {
    try {
      final String ext = p.extension(file.path).replaceFirst('.', '');
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final String fullPath = '$path/$fileName';
      final Uint8List bytes = await file.readAsBytes();

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            bytes,
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
