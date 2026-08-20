import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/theme/app_spacing.dart';
import 'package:bani_rasijan/core/theme/app_typography.dart';
import 'package:bani_rasijan/features/gallery/domain/photo_model.dart';
import 'package:bani_rasijan/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.periodId});
  final String periodId;

  static void show(BuildContext context, String periodId) {
    Navigator.pushNamed(
      context,
      '/gallery',
      arguments: periodId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(galleryPhotosStreamProvider(periodId));
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: () => _showPhotoPicker(context, ref),
              tooltip: 'Tambah Foto',
            ),
        ],
      ),
      body: photosAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorState(onRetry: () {
          ref.invalidate(galleryPhotosStreamProvider(periodId));
        }),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Belum ada foto', style: AppTypography.h3),
                  SizedBox(height: 8),
                  Text('Klik tombol + untuk menambah foto', style: AppTypography.body),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1,
                  ),
                  itemCount: photos.length + (isAdmin ? 1 : 0),
                  itemBuilder: (context, index) {
                    final photo = index < photos.length ? photos[index] : null;

                    if (photo == null) {
                      return _UploadPlaceholder(
                        onTap: () => _showPhotoPicker(context, ref),
                      );
                    }

                    return _PhotoTile(
                      photo: photo,
                      isAdmin: isAdmin,
                      onDelete: () => _showDeleteConfirmation(context, ref, photo),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPhotoPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ctx, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ctx, ref, ImageSource.camera);
              },
            ),
            const ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Batal'),
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920, // Resize for performance
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final uploadedBy = ref.read(currentMemberProfileProvider).valueOrNull?.id ?? '';

      ref.read(galleryUploadProvider.notifier).uploadPhoto(
            periodId: periodId,
            imageFile: file,
            uploadedBy: uploadedBy,
          );

      // Refresh photos after upload
      ref.invalidate(galleryPhotosStreamProvider(periodId));
    } catch (e) {
      AppSnackbar.show(context, 'Gagal memuat foto: $e');
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    PhotoModel photo,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Apakah Anda yakin ingin menghapus foto ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(galleryUploadProvider.notifier).deletePhoto(
                      photoId: photo.id,
                      storagePath: _getStoragePath(photo),
                    );
                ref.invalidate(galleryPhotosStreamProvider(periodId));
                AppSnackbar.show(context, 'Foto berhasil dihapus');
              } catch (e) {
                AppSnackbar.show(context, 'Gagal menghapus foto: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _getStoragePath(PhotoModel photo) {
    // Extract path from URL: https://.../event-photos/path/to/file.jpg -> path/to/file.jpg
    final uri = Uri.parse(photo.photoUrl);
    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      // The path we need is after 'event-photos'
      final bucketName = 'event-photos';
      final bucketIndex = segments.indexOf(bucketName);
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
    }
    // Fallback or error
    return '';
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isAdmin,
    required this.onDelete,
  });
  final PhotoModel photo;
  final bool isAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _showPhotoViewer(context, photo),
          child: Image.network(
            photo.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => const Center(
              child: Icon(Icons.broken_image, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (isAdmin)
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  void _showPhotoViewer(BuildContext context, PhotoModel photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _PhotoViewerScreen(photo: photo),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  const _PhotoViewerScreen({required this.photo});
  final PhotoModel photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            photo.photoUrl,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => const Center(
              child: Icon(Icons.broken_image, size: 64, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.add_photo_alternate, color: AppColors.primary),
        ),
      ),
    );
  }
}