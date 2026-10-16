import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../data/payments_repository.dart';
import '../providers/payments_providers.dart';

class DonationPaymentSettingsSheet extends ConsumerStatefulWidget {
  const DonationPaymentSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => AnimatedPadding(
          duration: MediaQuery.disableAnimationsOf(sheetContext)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: const DonationPaymentSettingsSheet(),
        ),
      );

  @override
  ConsumerState<DonationPaymentSettingsSheet> createState() =>
      _DonationPaymentSettingsSheetState();
}

class _DonationPaymentSettingsSheetState
    extends ConsumerState<DonationPaymentSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _picker = ImagePicker();

  bool _initialized = false;
  bool _saving = false;
  XFile? _newQris;
  String? _currentQrisPath;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _chooseQris() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 92,
    );
    if (image != null && mounted) setState(() => _newQris = image);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = ref.read(paymentsRepositoryProvider);
    String? uploadedPath;
    final oldPath = _currentQrisPath;
    try {
      var qrisPath = oldPath;
      if (_newQris != null) {
        final extension = _newQris!.name.split('.').last.toLowerCase();
        final safeExtension =
            const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
                ? extension
                : 'jpg';
        final contentType = safeExtension == 'png'
            ? 'image/png'
            : safeExtension == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
        uploadedPath = await repository.uploadQrisImage(
          bytes: await _newQris!.readAsBytes(),
          extension: safeExtension,
          contentType: contentType,
        );
        qrisPath = uploadedPath;
      }

      await repository.saveDonationPaymentSettings(
        bankName: _bankNameController.text.trim(),
        bankAccountName: _accountNameController.text.trim(),
        bankAccountNumber: _accountNumberController.text.trim(),
        qrisImagePath: qrisPath,
        paymentInstructions: _instructionsController.text.trim(),
      );
      final savedPath = uploadedPath;
      uploadedPath = null;
      if (oldPath != null && savedPath != null) {
        try {
          await repository.deleteQrisImage(oldPath);
        } catch (_) {}
      }
      ref.invalidate(donationPaymentSettingsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(context, 'Pengaturan donasi berhasil disimpan.');
    } catch (_) {
      if (uploadedPath != null) {
        try {
          await repository.deleteQrisImage(uploadedPath);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(
          context, 'Pengaturan gagal disimpan. Periksa koneksi dan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(donationPaymentSettingsProvider);
    final size = MediaQuery.sizeOf(context);
    final availableHeight =
        size.height - MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: availableHeight * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child:
                          Text('Pengaturan Donasi', style: AppTypography.h2)),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: settingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: AppErrorState(
                    onRetry: () =>
                        ref.invalidate(donationPaymentSettingsProvider),
                  ),
                ),
                data: (settings) {
                  if (!_initialized) {
                    _initialized = true;
                    _bankNameController.text = settings?.bankName ?? '';
                    _accountNameController.text =
                        settings?.bankAccountName ?? '';
                    _accountNumberController.text =
                        settings?.bankAccountNumber ?? '';
                    _instructionsController.text =
                        settings?.paymentInstructions ?? '';
                    _currentQrisPath = settings?.qrisImagePath;
                  }
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Text('Rekening tujuan', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama bank',
                            border: OutlineInputBorder(),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _accountNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama pemilik rekening',
                            border: OutlineInputBorder(),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nomor rekening tujuan',
                            border: OutlineInputBorder(),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('QRIS', style: AppTypography.h3),
                        const SizedBox(height: AppSpacing.sm),
                        _buildQrisPreview(
                            repository: ref.read(paymentsRepositoryProvider)),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _chooseQris,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                              _currentQrisPath == null && _newQris == null
                                  ? 'Unggah gambar QRIS'
                                  : 'Ganti gambar QRIS'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _instructionsController,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            labelText: 'Instruksi pembayaran',
                            hintText:
                                'Misalnya: masukkan nominal persis seperti yang tertera.',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Pengaturan ini hanya dapat diubah admin. QRIS menerima PNG, JPG, atau WebP hingga 2 MB.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                                _saving ? 'Menyimpan…' : 'Simpan pengaturan'),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.viewInsetsOf(context).bottom),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Widget _buildQrisPreview({required PaymentsRepository repository}) {
    if (_newQris != null) {
      return ClipRRect(
        borderRadius: AppRadii.card,
        child: Image.file(
          File(_newQris!.path),
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _QrisPlaceholder(),
        ),
      );
    }
    if (_currentQrisPath != null) {
      return ClipRRect(
        borderRadius: AppRadii.card,
        child: Image.network(
          repository.getQrisImageUrl(_currentQrisPath!),
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _QrisPlaceholder(),
        ),
      );
    }
    return const _QrisPlaceholder();
  }
}

class _QrisPlaceholder extends StatelessWidget {
  const _QrisPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.divider),
          borderRadius: AppRadii.card,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_rounded,
                  size: 42, color: AppColors.textSecondary),
              SizedBox(height: AppSpacing.xs),
              Text('Belum ada gambar QRIS'),
            ],
          ),
        ),
      );
}
