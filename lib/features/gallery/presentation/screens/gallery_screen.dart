import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_image_compress/src/compress_config.dart';
import 'package:smart_image_compress/src/compress_service.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../../periods/presentation/providers/periods_providers.dart';
import '../../domain/photo_model.dart';
import '../providers/gallery_providers.dart';

/// Screen galeri dokumentasi foto arisan keluarga.
/// Grid adaptif responsif, upload untuk semua anggota (kompresi otomatis),
/// fullscreen viewer dengan swipe + pinch-to-zoom.
class GalleryScreen extends ConsumerStatefulWidget {
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
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.periodId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, isUploading: false, onUpload: null),
        body: const _EmptyPeriodError(),
      );
    }

    final photosAsync = ref.watch(galleryPhotosStreamProvider(widget.periodId));
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;
    final currentUserId = currentMember?.id ?? '';

    final periodsAsync = ref.watch(periodsControllerProvider);
    final currentPeriod = periodsAsync.valueOrNull
        ?.where((p) => p.id == widget.periodId)
        .firstOrNull;
    final periodTitle = currentPeriod != null
        ? 'Arisan Periode #${currentPeriod.periodNumber}'
        : 'Dokumentasi Acara';

    final membersList = ref.watch(membersControllerProvider).valueOrNull ?? [];
    final membersMap = {for (final m in membersList) m.id: m.fullName};

    final isUploading = _isUploading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(
        context,
        isUploading: isUploading,
        onUpload: () => _showPhotoPicker(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : () => _showPhotoPicker(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
        icon: isUploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Icon(Icons.add_a_photo_rounded),
        label: Text(
          isUploading ? 'Mengunggah...' : 'Tambah Foto',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(galleryPhotosStreamProvider(widget.periodId));
            },
            child: photosAsync.when(
              loading: () => const Center(child: AppLoading()),
              error: (err, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  AppErrorState(
                    onRetry: () => ref.invalidate(
                        galleryPhotosStreamProvider(widget.periodId)),
                  ),
                ],
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return _EmptyGalleryState(
                    periodTitle: periodTitle,
                    onUpload:
                        isUploading ? null : () => _showPhotoPicker(context),
                  );
                }

                return _GalleryGrid(
                  photos: photos,
                  periodTitle: periodTitle,
                  periodId: widget.periodId,
                  isAdmin: isAdmin,
                  currentUserId: currentUserId,
                  membersMap: membersMap,
                  onDeletePhoto: (photo) =>
                      _showDeleteConfirmation(context, photo),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context, {
    required bool isUploading,
    required VoidCallback? onUpload,
  }) {
    return AppBar(
      title: const Text('Galeri Dokumentasi'),
      elevation: 0,
      scrolledUnderElevation: .5,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.h3,
      actions: [
        if (onUpload != null)
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: isUploading ? null : onUpload,
            tooltip: 'Tambah Foto',
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  void _showPhotoPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: AppRadii.small,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Tambah Foto Galeri', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pilih sumber foto dokumentasi arisan keluarga.',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: AppRadii.small,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Pilih dari Galeri',
                    style: AppTypography.bodyMedium),
                subtitle: Text(
                  'Ambil foto yang tersimpan di perangkat',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.card),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(context, ImageSource.gallery);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: .1),
                    borderRadius: AppRadii.small,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFE11D48),
                  ),
                ),
                title: const Text('Ambil Foto Baru',
                    style: AppTypography.bodyMedium),
                subtitle: Text(
                  'Gunakan kamera untuk memotret momen langsung',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.card),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    // Cegah upload ganda (tap cepat dua kali = 2 baris DB).
    if (_isUploading) return;
    final picker = ImagePicker();
    try {
      debugPrint('Opening image picker, source: $source');
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      debugPrint('Image picker returned: ${pickedFile?.path}');

      if (pickedFile == null) {
        debugPrint('User cancelled image picker');
        return;
      }

      // Validate file exists and is readable
      final originalFile = File(pickedFile.path);
      debugPrint('File exists: ${await originalFile.exists()}');
      debugPrint('File size: ${await originalFile.length()} bytes');

      if (!mounted) return;
      setState(() => _isUploading = true);
      // AppSnackbar pakai global messengerKey — aman walau context
      // ter-deactivate setelah kembali dari native picker.
      AppSnackbar.show(context, 'Sedang memproses foto...');

      // Compress image using smart_image_compress
      final compressionService = CompressionService();
      debugPrint('Compressing image: ${originalFile.path}');
      final compressedFile = await compressionService.compressSingleImage(
        originalFile,
        const CompressConfig(
          maxSizeKB: 500,
          maxResolution: 1920,
          initialQuality: 80,
        ),
      );
      debugPrint(
          'Compressed image: ${compressedFile.path} (${await compressedFile.length()} bytes)');

      if (!mounted) return;
      final uploadedBy =
          ref.read(currentMemberProfileProvider).valueOrNull?.id ?? '';
      debugPrint('Uploading by user: $uploadedBy');

      if (uploadedBy.isEmpty) {
        throw Exception('User ID tidak ditemukan. Silakan login ulang.');
      }

      final repo = ref.read(galleryRepositoryProvider);
      debugPrint('Uploading to storage...');
      final photoUrl = await repo.uploadPhotoToStorage(
        periodId: widget.periodId,
        imageFile: compressedFile,
      );
      debugPrint('Storage upload success: $photoUrl');

      debugPrint('Saving to database...');
      await repo.uploadPhoto(
        periodId: widget.periodId,
        photoUrl: photoUrl,
        uploadedBy: uploadedBy,
      );
      debugPrint('Database save success');

      if (!mounted) return;
      // Tanpa invalidate: stream realtime dorong baris baru otomatis.
      // Invalidate di sini balapan dengan event realtime => duplikat sesaat.
      AppSnackbar.show(
          context, 'Foto berhasil ditambahkan ke galeri keluarga!');
    } catch (e, st) {
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $st');
      if (mounted) {
        AppSnackbar.show(context, 'Gagal mengunggah foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    PhotoModel photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: const Text('Hapus Foto Galeri?', style: AppTypography.h3),
        content: const Text(
          'Foto ini akan dihapus permanen dari galeri dokumentasi keluarga.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style:
                  AppTypography.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Hapus',
              style: AppTypography.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false)) {
      if (!mounted) return;
      final repo = ref.read(galleryRepositoryProvider);
      // Storage dulu: policy DELETE storage verifikasi kepemilikan via baris
      // event_photos, jadi file harus dihapus selagi baris DB masih ada.
      // Jika storage gagal, batalkan agar tidak jadi yatim.
      try {
        final storagePath = _getStoragePath(photo);
        if (storagePath.isNotEmpty) {
          await repo.deletePhotoFromStorage(storagePath);
        }
      } catch (e) {
        debugPrint('Gallery delete: hapus storage gagal: $e');
        if (mounted) {
          AppSnackbar.show(context, 'Gagal menghapus file foto: $e');
        }
        return;
      }
      // DB kemudian: deletePhoto lempar exception jika 0 baris (RLS blokir).
      try {
        await repo.deletePhoto(photo.id);
      } catch (e) {
        debugPrint('Gallery delete: hapus DB gagal: $e');
        if (mounted) {
          AppSnackbar.show(context, 'Gagal menghapus foto: $e');
        }
        return;
      }
      if (!mounted) return;
      ref.invalidate(galleryPhotosStreamProvider(widget.periodId));
      AppSnackbar.show(context, 'Foto berhasil dihapus');
    }
  }

  String _getStoragePath(PhotoModel photo) {
    const bucketName = 'event-photos';
    final segments = Uri.parse(photo.photoUrl).pathSegments;
    final bucketIndex = segments.indexOf(bucketName);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return '';
    var path = segments.sublist(bucketIndex + 1).join('/');
    // URL lama menyimpan prefix bucket ganda; remove() butuh path relatif bucket.
    const dupPrefix = '$bucketName/';
    if (path.startsWith(dupPrefix)) {
      path = path.substring(dupPrefix.length);
    }
    return path;
  }
}

/// Grid galeri dengan LayoutBuilder adaptif dan staggered entrance animation.
class _GalleryGrid extends StatefulWidget {
  const _GalleryGrid({
    required this.photos,
    required this.periodTitle,
    required this.periodId,
    required this.isAdmin,
    required this.currentUserId,
    required this.membersMap,
    required this.onDeletePhoto,
  });

  final List<PhotoModel> photos;
  final String periodTitle;
  final String periodId;
  final bool isAdmin;
  final String currentUserId;
  final Map<String, String> membersMap;
  final void Function(PhotoModel) onDeletePhoto;

  @override
  State<_GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<_GalleryGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300 + (widget.photos.length.clamp(0, 15) * 40),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _animController.value = 1.0;
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount =
            width > 700 ? 5 : width > 480 ? 4 : 3;

        final totalPhotos = widget.photos.length;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderCard(totalPhotos),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                96, // Jarak untuk FloatingActionButton
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1,
                ),
                itemCount: totalPhotos,
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  final canDelete = widget.isAdmin ||
                      (widget.currentUserId.isNotEmpty &&
                          photo.uploadedBy == widget.currentUserId);

                  final startFraction =
                      (index / (totalPhotos + 2)).clamp(0.0, 1.0);
                  final endFraction =
                      ((index + 2) / (totalPhotos + 2)).clamp(0.0, 1.0);

                  final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _animController,
                      curve: Interval(startFraction, endFraction,
                          curve: Curves.easeOut),
                    ),
                  );

                  final scaleAnim =
                      Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animController,
                      curve: Interval(startFraction, endFraction,
                          curve: Curves.easeOutCubic),
                    ),
                  );

                  return FadeTransition(
                    opacity: fadeAnim,
                    child: ScaleTransition(
                      scale: scaleAnim,
                      child: _PhotoTile(
                        photo: photo,
                        canDelete: canDelete,
                        onTap: () => _openPhotoViewer(index),
                        onDelete: () => widget.onDeletePhoto(photo),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCard(int totalPhotos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFFE11D48),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.periodTitle, style: AppTypography.h3),
                const SizedBox(height: 2),
                Text(
                  'Arsip momen dan kebersamaan keluarga.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: AppRadii.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalPhotos Foto',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPhotoViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => _PhotoViewerScreen(
          photos: widget.photos,
          initialIndex: initialIndex,
          periodTitle: widget.periodTitle,
          isAdmin: widget.isAdmin,
          currentUserId: widget.currentUserId,
          membersMap: widget.membersMap,
          periodId: widget.periodId,
        ),
      ),
    );
  }
}

/// Satu kartu foto dalam grid dengan rounded corners dan tombol aksi.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final PhotoModel photo;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: .6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Hero(
              tag: 'gallery-photo-${photo.id}',
              child: Image.network(
                photo.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.background,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, err, st) => Container(
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (canDelete)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withValues(alpha: .5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fullscreen photo viewer: swipe PageView + pinch-to-zoom + metadata.
class _PhotoViewerScreen extends ConsumerStatefulWidget {
  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    required this.periodTitle,
    required this.isAdmin,
    required this.currentUserId,
    required this.membersMap,
    required this.periodId,
  });

  final List<PhotoModel> photos;
  final int initialIndex;
  final String periodTitle;
  final bool isAdmin;
  final String currentUserId;
  final Map<String, String> membersMap;
  final String periodId;

  @override
  ConsumerState<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<PhotoModel> _photos;
  bool _showOverlays = true;

  @override
  void initState() {
    super.initState();
    _photos = List<PhotoModel>.from(widget.photos);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleOverlays() {
    setState(() {
      _showOverlays = !_showOverlays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = _photos.isNotEmpty ? _photos[_currentIndex] : null;
    final canDelete = currentPhoto != null &&
        (widget.isAdmin ||
            (widget.currentUserId.isNotEmpty &&
                currentPhoto.uploadedBy == widget.currentUserId));

    final uploaderName = currentPhoto != null
        ? (widget.membersMap[currentPhoto.uploadedBy] ?? 'Anggota Keluarga')
        : '';
    final uploadedDate = currentPhoto?.uploadedAt != null
        ? Formatters.formatDate(currentPhoto!.uploadedAt!)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleOverlays,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'gallery-photo-${photo.id}',
                      child: Image.network(
                        photo.photoUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 54,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showOverlays ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showOverlays,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Kembali',
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentIndex + 1} dari ${_photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.periodTitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: _confirmDeleteCurrentPhoto,
                          tooltip: 'Hapus Foto',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showOverlays ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showOverlays,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: .8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            uploaderName.isNotEmpty
                                ? uploaderName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Diupload oleh $uploaderName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (uploadedDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                uploadedDate,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCurrentPhoto() async {
    final photo = _photos[_currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: const Text('Hapus Foto Ini?', style: AppTypography.h3),
        content: const Text(
          'Foto ini akan dihapus permanen dari galeri dokumentasi keluarga.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style:
                  AppTypography.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Hapus',
              style: AppTypography.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false)) {
      if (!mounted) return;
      final repo = ref.read(galleryRepositoryProvider);
      // Storage dulu (policy cek kepemilikan via baris DB), DB kemudian.
      try {
        final storagePath = _extractStoragePath(photo);
        if (storagePath.isNotEmpty) {
          await repo.deletePhotoFromStorage(storagePath);
        }
      } catch (e) {
        debugPrint('Gallery delete: hapus storage gagal: $e');
        if (mounted) {
          AppSnackbar.show(context, 'Gagal menghapus file foto: $e');
        }
        return;
      }
      try {
        await repo.deletePhoto(photo.id);
      } catch (e) {
        debugPrint('Gallery delete: hapus DB gagal: $e');
        if (mounted) {
          AppSnackbar.show(context, 'Gagal menghapus foto: $e');
        }
        return;
      }
      if (!mounted) return;
      ref.invalidate(galleryPhotosStreamProvider(widget.periodId));
      AppSnackbar.show(context, 'Foto berhasil dihapus');

        if (_photos.length <= 1) {
          Navigator.pop(context);
        } else {
          setState(() {
            _photos.removeAt(_currentIndex);
            if (_currentIndex >= _photos.length) {
              _currentIndex = _photos.length - 1;
            }
          });
        }
    }
  }

  String _extractStoragePath(PhotoModel photo) {
    const bucketName = 'event-photos';
    final segments = Uri.parse(photo.photoUrl).pathSegments;
    final bucketIndex = segments.indexOf(bucketName);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return '';
    var path = segments.sublist(bucketIndex + 1).join('/');
    // URL lama menyimpan prefix bucket ganda; remove() butuh path relatif bucket.
    const dupPrefix = '$bucketName/';
    if (path.startsWith(dupPrefix)) {
      path = path.substring(dupPrefix.length);
    }
    return path;
  }
}

/// Tampilan kosong ketika belum ada foto di galeri.
class _EmptyGalleryState extends StatelessWidget {
  const _EmptyGalleryState({
    required this.periodTitle,
    required this.onUpload,
  });

  final String periodTitle;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 44,
              color: Color(0xFFE11D48),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Belum Ada Foto Dokumentasi',
          style: AppTypography.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Abadikan momen hangat arisan keluarga di $periodTitle. Semua anggota keluarga dapat mengunggah foto bersama!',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (onUpload != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: const Text('Unggah Foto Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.button,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.mdSm,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tampilan error jika ID periode tidak valid.
class _EmptyPeriodError extends StatelessWidget {
  const _EmptyPeriodError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AppCard(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              SizedBox(height: AppSpacing.md),
              Text('ID periode tidak valid.', style: AppTypography.h3),
            ],
          ),
        ),
      ),
    );
  }
}
