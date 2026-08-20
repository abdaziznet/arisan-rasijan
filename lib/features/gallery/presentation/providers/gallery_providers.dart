import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gallery_repository.dart';
import 'package:bani_rasijan/features/gallery/domain/photo_model.dart';

/// Provider for GalleryRepository instance.
final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});

/// FutureProvider that fetches photos for a specific period.
/// The periodId is passed via a family modifier.
final galleryPhotosProvider = FutureProvider.family<List<PhotoModel>, String>(
    (ref, periodId) async {
  final repo = ref.watch(galleryRepositoryProvider);
  return await repo.getPhotosForPeriod(periodId);
});

/// StreamProvider that listens for realtime updates to photos for a period.
final galleryPhotosStreamProvider =
    StreamProvider.family<List<PhotoModel>, String>((ref, periodId) {
  final repo = ref.watch(galleryRepositoryProvider);
  return repo.watchPhotosForPeriod(periodId);
});

/// StateNotifierProvider for handling photo upload state.
class GalleryUploadNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  GalleryUploadNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> uploadPhoto({
    required String periodId,
    required File imageFile,
    required String uploadedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(galleryRepositoryProvider);
      // First upload to storage to get the public URL
      final photoUrl =
          await repo.uploadPhotoToStorage(periodId: periodId, imageFile: imageFile);
      // Then insert into the database
      await repo.uploadPhoto(
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
      final repo = ref.read(galleryRepositoryProvider);
      await repo.deletePhoto(photoId);
      await repo.deletePhotoFromStorage(storagePath);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final galleryUploadProvider =
    StateNotifierProvider<GalleryUploadNotifier, AsyncValue<void>>((ref) {
  return GalleryUploadNotifier(ref);
});
