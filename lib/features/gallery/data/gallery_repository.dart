import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/photo_model.dart';

class GalleryRepository {
  GalleryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<PhotoModel>> getPhotosForPeriod(String periodId) async {
    final response = await _client
        .from('event_photos')
        .select()
        .eq('period_id', periodId)
        .order('uploaded_at', ascending: false);

    final list = response as List<dynamic>;
    return list.map((json) => PhotoModel.fromJson(json)).toList();
  }

  Future<PhotoModel> uploadPhoto({
    required String periodId,
    required String photoUrl,
    required String uploadedBy,
  }) async {
    final response = await _client
        .from('event_photos')
        .insert({
          'period_id': periodId,
          'photo_url': photoUrl,
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return PhotoModel.fromJson(response);
  }

  /// Hapus baris foto. Lempar exception jika 0 baris terhapus
  /// (misal RLS memblokir) agar kegagalan tidak diam-diam.
  Future<void> deletePhoto(String photoId) async {
    final response = await _client
        .from('event_photos')
        .delete()
        .eq('id', photoId)
        .select('id');
    final list = response as List<dynamic>;
    if (list.isEmpty) {
      throw Exception(
        'Baris foto tidak terhapus (kemungkinan diblokir aturan akses). '
        'Hanya pemilik foto atau admin yang boleh menghapus.',
      );
    }
  }

  Stream<List<PhotoModel>> watchPhotosForPeriod(String periodId) {
    return _client
        .from('event_photos')
        .stream(primaryKey: ['id'])
        .eq('period_id', periodId)
        .order('uploaded_at', ascending: false)
        .map((data) {
          // Dedup by id: invalidate tepat setelah insert bisa balapan
          // dengan event realtime sehingga baris baru muncul dua kali sesaat.
          final seen = <String, PhotoModel>{};
          for (final row in data) {
            final photo = PhotoModel.fromJson(row);
            seen[photo.id] = photo;
          }
          return seen.values.toList();
        });
  }

  Future<String> uploadPhotoToStorage({
    required String periodId,
    required File imageFile,
  }) async {
    final fileExt = 'webp'; // smart_image_compress outputs WebP
    final fileName =
        '$periodId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      // Abaikan nilai balik upload(): SDK mengembalikan key berawalan
      // nama bucket sehingga getPublicUrl(path) menghasilkan URL dobel
      // prefix (.../event-photos/event-photos/...) yang 404 saat dibuka.
      // Bangun public URL dari fileName yang kita tentukan sendiri.
      await _client.storage.from('event-photos').upload(fileName, imageFile);

      return _client.storage.from('event-photos').getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  Future<void> deletePhotoFromStorage(String filePath) async {
    await _client.storage.from('event-photos').remove([filePath]);
  }
}