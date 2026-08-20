import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gallery_repository.dart';

class GalleryController extends StateNotifier<AsyncValue<void>> {
  GalleryController(this._galleryRepository) : super(const AsyncValue.data(null));

  final GalleryRepository _galleryRepository;

  Future<void> uploadPhoto({
    required String periodId,
    required File imageFile,
    required String uploadedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      // First upload to storage to get the public URL
      final photoUrl =
          await _galleryRepository.uploadPhotoToStorage(
              periodId: periodId, imageFile: imageFile);
      // Then insert into the database
      await _galleryRepository.uploadPhoto(
        periodId: periodId,
        photoUrl: photoUrl,
        uploadedBy: uploadedBy,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _galleryRepository.deletePhoto(photoId);
      await _galleryRepository.deletePhotoFromStorage(storagePath);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final galleryControllerProvider =
    StateNotifierProvider<GalleryController, AsyncValue<void>>((ref) {
  return GalleryController(GalleryRepository());
});
