import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload foto profil ke Supabase Storage
  static Future<String> uploadProfilePhoto(
    File imageFile,
    String userId,
  ) async {
    try {
      // Validasi file
      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }

      // Validasi ukuran file (max 3MB)
      final fileSize = await imageFile.length();
      if (fileSize > 3 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (maksimal 3MB)');
      }

      // Validasi file tidak kosong
      if (fileSize == 0) {
        throw Exception('File kosong');
      }

      // Generate unique filename
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      final storagePath = 'profile_photos/$fileName';

      // Read file as bytes dengan timeout
      final bytes = await imageFile.readAsBytes().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout membaca file'),
      );

      // Upload to Supabase Storage dengan timeout
      await _supabase.storage
          .from('profile')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Timeout upload ke server'),
          );

      // Get public URL
      final url = _supabase.storage.from('profile').getPublicUrl(storagePath);

      return url;
    } catch (e) {
      print('Error in uploadProfilePhoto: $e');
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Delete foto profil dari Supabase Storage
  static Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final storagePath = '${pathSegments[2]}/${pathSegments[3]}';
        await _supabase.storage.from('profile').remove([storagePath]);
      }
    } catch (e) {
      print('Error deleting profile photo: $e');
    }
  }

  /// Upload file umum ke Supabase Storage
  static Future<String> uploadFile(
    File file,
    String bucket,
    String path,
  ) async {
    try {
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}
