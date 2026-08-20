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

  Future<void> deletePhoto(String photoId) async {
    await _client.from('event_photos').delete().eq('id', photoId);
  }

  Stream<List<PhotoModel>> watchPhotosForPeriod(String periodId) {
    return _client
        .from('event_photos')
        .stream(primaryKey: ['id'])
        .eq('period_id', periodId)
        .order('uploaded_at', ascending: false)
        .map((data) =>
            data.map((json) => PhotoModel.fromJson(json)).toList());
  }

  Future<String> uploadPhotoToStorage({
    required String periodId,
    required File imageFile,
  }) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName =
        '$periodId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      final path = await _client.storage
          .from('event-photos')
          .upload(fileName, imageFile);

      final publicUrl = _client.storage.from('event-photos').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  Future<void> deletePhotoFromStorage(String filePath) async {
    await _client.storage.from('event-photos').remove([filePath]);
  }
}