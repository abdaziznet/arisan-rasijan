import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../members/presentation/providers/members_providers.dart';
import '../../domain/payment_model.dart';
import '../controllers/donation_form_controller.dart';
import '../controllers/payment_list_controller.dart';
import '../providers/payments_providers.dart';

class DonationFormDialog extends ConsumerStatefulWidget {
  const DonationFormDialog({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final reduceMotion = MediaQuery.disableAnimationsOf(sheetContext);
          return AnimatedPadding(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: const DonationFormDialog(),
            ),
          );
        },
      );

  @override
  ConsumerState<DonationFormDialog> createState() => _DonationFormDialogState();
}

class _DonationFormDialogState extends ConsumerState<DonationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  final _picker = ImagePicker();

  static const _quickAmounts = [25000, 50000, 100000, 200000, 500000];
  static const _paymentMethods = <String, String>{
    'cash': 'Tunai',
    'transfer': 'Transfer',
    'qris': 'QRIS',
  };

  String? _paymentMethod;
  double? _quickAmount;
  Donation? _createdDonation;
  XFile? _proofImage;
  bool _isSaving = false;
  bool _isDownloadingQris = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _createDonation() async {
    if (!_formKey.currentState!.validate()) return;
    final member = ref.read(currentMemberProfileProvider).valueOrNull;
    final amount = double.tryParse(_amountController.text.trim());
    if (member == null || amount == null || _paymentMethod == null) return;

    setState(() => _isSaving = true);
    final donation =
        await ref.read(donationFormProvider.notifier).submitDonation(
              memberId: member.id,
              amount: amount,
              paymentMethod: _paymentMethod!,
              notes: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _createdDonation = donation;
    });
    if (donation == null) {
      AppSnackbar.show(context, 'Donasi belum dapat disimpan. Coba lagi.');
      return;
    }
    ref.invalidate(donationListProvider);
  }

  Future<void> _chooseProof() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _proofImage = image);
  }

  Future<void> _markPaymentSent() async {
    final donation = _createdDonation;
    if (donation == null) return;
    setState(() => _isSaving = true);
    try {
      String? proofPath;
      if (_proofImage != null) {
        final extension = _proofImage!.name.split('.').last.toLowerCase();
        final safeExtension =
            const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
                ? extension
                : 'jpg';
        final contentType = safeExtension == 'png'
            ? 'image/png'
            : safeExtension == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
        proofPath =
            await ref.read(paymentsRepositoryProvider).uploadDonationProof(
                  donationId: donation.id,
                  bytes: await _proofImage!.readAsBytes(),
                  extension: safeExtension,
                  contentType: contentType,
                );
      }
      await ref.read(paymentsRepositoryProvider).markDonationPaymentSent(
            donationId: donation.id,
            paymentMethod: donation.paymentMethod,
            paymentReference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
            paymentProofPath: proofPath,
          );
      ref.invalidate(donationListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.show(
          context, 'Pembayaran dilaporkan. Menunggu verifikasi admin.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.show(context, 'Laporan pembayaran gagal dikirim. Coba lagi.');
    }
  }

  Future<void> _downloadQris(String path) async {
    setState(() => _isDownloadingQris = true);
    try {
      if (kIsWeb) {
        final extension = path.split('.').last;
        final downloadName =
            'QRIS-donasi-${DateTime.now().millisecondsSinceEpoch}.$extension';
        final url = ref.read(paymentsRepositoryProvider).getQrisImageUrl(path);
        final downloadUri = Uri.parse(url).replace(
          queryParameters: {'download': downloadName},
        );
        if (!await launchUrl(downloadUri)) {
          throw Exception('Browser tidak dapat memulai unduhan.');
        }
        if (mounted) AppSnackbar.show(context, 'Unduhan QRIS dimulai.');
        return;
      }

      var hasGalleryAccess = await Gal.hasAccess();
      if (!hasGalleryAccess) {
        hasGalleryAccess = await Gal.requestAccess();
      }
      if (!hasGalleryAccess) {
        if (mounted) {
          AppSnackbar.show(
            context,
            'Izin akses galeri diperlukan untuk menyimpan QRIS.',
          );
        }
        return;
      }

      final imageBytes =
          await ref.read(paymentsRepositoryProvider).downloadQrisImage(path);
      await Gal.putImageBytes(
        imageBytes,
        name: 'qris-donasi-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted)
        AppSnackbar.show(context, 'QRIS berhasil disimpan ke galeri.');
    } on GalException {
      if (mounted) {
        AppSnackbar.show(context,
            'QRIS gagal disimpan. Periksa izin dan ruang penyimpanan.');
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'QRIS gagal diunduh. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isDownloadingQris = false);
    }
  }

  void _selectAmount(int amount) {
    setState(() {
      _quickAmount = amount.toDouble();
      _amountController.text = amount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProfileProvider).valueOrNull;
    final formState = ref.watch(donationFormProvider);
    final settingsAsync = ref.watch(donationPaymentSettingsProvider);
    final isLoading = _isSaving || formState == DonationFormState.loading;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight =
        (screenHeight - keyboardHeight).clamp(0.0, screenHeight).toDouble();
    final maxHeight = availableHeight * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
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
                AppSpacing.lg,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _createdDonation == null
                          ? 'Buat Laporan Donasi'
                          : 'Instruksi Pembayaran',
                      style: AppTypography.h2,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _createdDonation == null
                  ? _buildDonationForm(
                      currentMember?.fullName ?? 'Akun Anda', isLoading)
                  : _buildPaymentInstructions(settingsAsync, isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationForm(String memberName, bool isLoading) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: AppRadii.card,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Donasi dicatat atas nama $memberName',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Pilih metode pembayaran', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _paymentMethods.entries.map((entry) {
              final selected = _paymentMethod == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: isLoading
                    ? null
                    : (_) => setState(() => _paymentMethod = entry.key),
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.button,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.divider,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Nominal donasi', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _quickAmounts.map((amount) {
              final selected = _quickAmount == amount.toDouble();
              return ChoiceChip(
                label: Text(Formatters.formatCurrency(amount.toDouble())),
                selected: selected,
                onSelected: isLoading ? null : (_) => _selectAmount(amount),
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.caption.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.small,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.divider,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            scrollPadding: const EdgeInsets.only(bottom: 160),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nominal (Rp)',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (_quickAmount != double.tryParse(value)) {
                setState(() => _quickAmount = null);
              }
            },
            validator: (value) {
              final amount = int.tryParse(value ?? '');
              if (amount == null || amount <= 0)
                return 'Masukkan nominal donasi';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 200,
            scrollPadding: const EdgeInsets.only(bottom: 160),
            decoration: const InputDecoration(
              labelText: 'Pesan (opsional)',
              hintText: 'Doa atau pesan untuk keluarga',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed:
                  isLoading || _paymentMethod == null ? null : _createDonation,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(isLoading ? 'Menyimpan…' : 'Lanjut ke pembayaran'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Donasi baru berstatus menunggu pembayaran sampai Anda melaporkan pembayaran dan admin memverifikasinya.',
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(
    AsyncValue<DonationPaymentSettings?> settingsAsync,
    bool isLoading,
  ) {
    final donation = _createdDonation!;
    final method = donation.paymentMethod ?? 'cash';
    final payable = donation.paymentAmount ?? donation.amount;
    final settings = settingsAsync.valueOrNull;
    final destinationReady = method == 'cash' ||
        (method == 'transfer' &&
            settings?.bankAccountNumber?.isNotEmpty == true) ||
        (method == 'qris' && settings?.qrisImagePath?.isNotEmpty == true);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: AppRadii.card,
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nominal yang perlu dibayar', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      Formatters.formatCurrency(payable),
                      style: AppTypography.h1
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin nominal',
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: payable.toInt().toString()),
                    ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              if (donation.uniqueCode != null)
                Text(
                  'Kode unik ${donation.uniqueCode!.toString().padLeft(3, '0')} sudah ditambahkan. Transfer tepat sesuai nominal di atas.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (method == 'cash')
          const _InstructionCard(
            icon: Icons.payments_outlined,
            title: 'Pembayaran tunai',
            body:
                'Serahkan uang kepada admin. Donasi akan sah setelah admin menghitung dan mengonfirmasi penerimaannya.',
          )
        else
          settingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const _InstructionCard(
              icon: Icons.info_outline_rounded,
              title: 'Instruksi belum tersedia',
              body:
                  'Pengaturan pembayaran tidak dapat dimuat. Silakan coba lagi nanti.',
            ),
            data: (settings) => _buildConfiguredPayment(method, settings),
          ),
        if (method != 'cash') ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _referenceController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Referensi transaksi (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _chooseProof,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(_proofImage?.name ?? 'Lampirkan bukti (opsional)'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: isLoading || !destinationReady ? null : _markPaymentSent,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(method == 'cash'
                ? 'Uang sudah diserahkan'
                : 'Saya sudah bayar'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Bayar nanti'),
        ),
      ],
    );
  }

  Widget _buildConfiguredPayment(
    String method,
    DonationPaymentSettings? settings,
  ) {
    if (settings == null) {
      return const _InstructionCard(
        icon: Icons.info_outline_rounded,
        title: 'Pengaturan pembayaran belum tersedia',
        body: 'Hubungi admin sebelum melakukan pembayaran.',
      );
    }

    if (method == 'transfer') {
      return _InstructionCard(
        icon: Icons.account_balance_outlined,
        title: settings.bankName?.isNotEmpty == true
            ? settings.bankName!
            : 'Transfer bank',
        body: [
          if (settings.bankAccountName?.isNotEmpty == true)
            'Atas nama ${settings.bankAccountName}',
          if (settings.bankAccountNumber?.isNotEmpty == true)
            'Nomor rekening: ${settings.bankAccountNumber}',
          if (settings.paymentInstructions?.isNotEmpty == true)
            settings.paymentInstructions!,
        ].join('\n'),
      );
    }

    final path = settings.qrisImagePath;
    final imageUrl = path == null
        ? null
        : ref.read(paymentsRepositoryProvider).getQrisImageUrl(path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null) ...[
          Container(
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: AppRadii.card,
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('Gambar QRIS gagal dimuat.'),
              )),
          if (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isDownloadingQris ? null : () => _downloadQris(path!),
              icon: _isDownloadingQris
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                  _isDownloadingQris ? 'Menyimpan QRIS…' : 'Download QRIS'),
            ),
          ],
        ] else
          const _InstructionCard(
            icon: Icons.qr_code_2_rounded,
            title: 'QRIS belum diatur',
            body:
                'Admin belum mengunggah gambar QRIS. Silakan gunakan metode pembayaran lain.',
          ),
        if (settings.paymentInstructions?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(settings.paymentInstructions!, style: AppTypography.body),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Masukkan nominal tepat ${Formatters.formatCurrency(_createdDonation!.paymentAmount ?? _createdDonation!.amount)} pada aplikasi pembayaran.',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body.isEmpty
                        ? 'Silakan hubungi admin untuk instruksi.'
                        : body,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
