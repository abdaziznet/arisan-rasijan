import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/payment_model.dart';
import '../controllers/payment_list_controller.dart';
import '../providers/payments_providers.dart';

class DonationDetailsSheet extends ConsumerStatefulWidget {
  const DonationDetailsSheet({
    super.key,
    required this.donation,
    required this.isAdmin,
    this.memberName,
  });

  static Future<void> show(
    BuildContext context, {
    required Donation donation,
    required bool isAdmin,
    String? memberName,
  }) =>
      showModalBottomSheet<void>(
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
          child: DonationDetailsSheet(
            donation: donation,
            isAdmin: isAdmin,
            memberName: memberName,
          ),
        ),
      );

  final Donation donation;
  final bool isAdmin;
  final String? memberName;

  @override
  ConsumerState<DonationDetailsSheet> createState() =>
      _DonationDetailsSheetState();
}

class _DonationDetailsSheetState extends ConsumerState<DonationDetailsSheet> {
  final _referenceController = TextEditingController();
  final _picker = ImagePicker();
  late Donation _donation;
  XFile? _proofImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _donation = widget.donation;
    _referenceController.text = _donation.paymentReference ?? '';
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  bool get _canMemberReport =>
      !widget.isAdmin &&
      const {'pending_payment', 'pending_verification', 'needs_review'}
          .contains(_donation.status);

  Future<void> _pickProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _proofImage = picked);
  }

  Future<void> _sendPaymentReport() async {
    setState(() => _saving = true);
    try {
      String? proofPath = _donation.paymentProofPath;
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
                  donationId: _donation.id,
                  bytes: await _proofImage!.readAsBytes(),
                  extension: safeExtension,
                  contentType: contentType,
                );
      }
      await ref.read(paymentsRepositoryProvider).markDonationPaymentSent(
            donationId: _donation.id,
            paymentMethod: _donation.paymentMethod,
            paymentReference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
            paymentProofPath: proofPath,
          );
      ref.invalidate(donationListProvider);
      if (!mounted) return;
      AppSnackbar.show(context, 'Laporan pembayaran dikirim ke admin.');
      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('[DonationDetailsSheet] Payment report failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(context, 'Laporan pembayaran gagal dikirim. Coba lagi.');
    }
  }

  Future<void> _adminAction(String status) async {
    final result = await showDialog<_DonationReviewResult>(
      context: context,
      builder: (_) => _DonationReviewDialog(
        status: status,
        initialAmount: _donation.paymentAmount ?? _donation.amount,
      ),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(paymentsRepositoryProvider).verifyDonation(
            donationId: _donation.id,
            status: status,
            receivedAmount: result.receivedAmount,
            note: result.note,
          );
      ref.invalidate(donationListProvider);
      ref.invalidate(verifiedDonationTotalProvider);
      if (!mounted) return;
      setState(() {
        _donation = _donation.copyWith(
          status: status,
          receivedAmount: result.receivedAmount,
          verificationNote: result.note,
        );
        _saving = false;
      });
      AppSnackbar.show(context, 'Status donasi berhasil diperbarui.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(context, 'Verifikasi gagal disimpan. Coba lagi.');
    }
  }

  Future<void> _viewProof() async {
    final path = _donation.paymentProofPath;
    if (path == null) return;
    try {
      final url =
          await ref.read(paymentsRepositoryProvider).getDonationProofUrl(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Bukti pembayaran tidak dapat ditampilkan.'),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                child: IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        AppSnackbar.show(context, 'Bukti pembayaran tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(donationPaymentSettingsProvider);
    final statusLabel = _statusLabel(_donation.status);
    final methodLabel = _methodLabel(_donation.paymentMethod);
    final payable = _donation.paymentAmount ?? _donation.amount;
    final canReport =
        _canMemberReport && _paymentDestinationReady(settingsAsync);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;

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
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.isAdmin
                          ? 'Verifikasi Donasi'
                          : 'Detail Donasi Saya',
                      style: AppTypography.h2,
                    ),
                  ),
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
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: ListView(
                  key: ValueKey('${_donation.id}-${_donation.status}'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _DonationInfoCard(
                      donation: _donation,
                      memberName: widget.isAdmin ? widget.memberName : null,
                      statusLabel: statusLabel,
                      methodLabel: methodLabel,
                      payable: payable,
                    ),
                    if (_donation.notes?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Pesan', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_donation.notes!, style: AppTypography.body),
                    ],
                    if (_donation.verificationNote?.trim().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: AppSpacing.md),
                      _NoteCard(text: _donation.verificationNote!),
                    ],
                    if (_donation.paymentProofPath != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _viewProof,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Lihat bukti pembayaran'),
                      ),
                    ],
                    if (_canMemberReport) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildMemberPaymentInfo(settingsAsync),
                      if (_donation.paymentMethod != 'cash') ...[
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _referenceController,
                          maxLength: 100,
                          scrollPadding: const EdgeInsets.only(bottom: 160),
                          decoration: const InputDecoration(
                            labelText: 'Referensi transaksi (opsional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickProof,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: Text(_proofImage?.name ??
                              'Lampirkan bukti (opsional)'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed:
                              _saving || !canReport ? null : _sendPaymentReport,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(_donation.paymentMethod == 'cash'
                              ? 'Uang sudah diserahkan'
                              : 'Saya sudah bayar'),
                        ),
                      ),
                    ],
                    if (widget.isAdmin && _canAdminReview) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Tindakan admin', style: AppTypography.h3),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed:
                              _saving ? null : () => _adminAction('verified'),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Konfirmasi dana diterima'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _adminAction('needs_review'),
                            icon: const Icon(Icons.error_outline_rounded),
                            label: const Text('Perlu diperiksa'),
                          ),
                          TextButton.icon(
                            onPressed:
                                _saving ? null : () => _adminAction('rejected'),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Tolak'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canAdminReview => const {
        'pending_payment',
        'pending_verification',
        'needs_review'
      }.contains(_donation.status);

  bool _paymentDestinationReady(AsyncValue<DonationPaymentSettings?> settings) {
    if (_donation.paymentMethod == 'cash') return true;
    final value = settings.valueOrNull;
    if (value == null) return false;
    if (_donation.paymentMethod == 'transfer') {
      return value.bankAccountNumber?.isNotEmpty == true;
    }
    return value.qrisImagePath?.isNotEmpty == true;
  }

  Widget _buildMemberPaymentInfo(
      AsyncValue<DonationPaymentSettings?> settings) {
    if (_donation.paymentMethod == 'cash') {
      return const _NoteCard(
        text:
            'Serahkan uang kepada admin. Donasi akan disahkan setelah admin menghitung dan mengonfirmasi penerimaan.',
      );
    }
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _NoteCard(text: 'Instruksi pembayaran tidak dapat dimuat.'),
      data: (value) {
        if (value == null)
          return const _NoteCard(
              text: 'Admin belum mengatur informasi pembayaran.');
        if (_donation.paymentMethod == 'transfer') {
          return _NoteCard(
            text: '${value.bankName ?? 'Transfer bank'}\n'
                'Atas nama: ${value.bankAccountName ?? '-'}\n'
                'Nomor rekening: ${value.bankAccountNumber ?? '-'}\n'
                '${value.paymentInstructions ?? ''}',
          );
        }
        final path = value.qrisImagePath;
        if (path == null)
          return const _NoteCard(text: 'Admin belum mengunggah gambar QRIS.');
        return Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.divider),
              ),
              child: Image.network(
                ref.read(paymentsRepositoryProvider).getQrisImageUrl(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('Gambar QRIS gagal dimuat.'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
                value.paymentInstructions ??
                    'Masukkan nominal tepat seperti yang tertera.',
                style: AppTypography.body),
          ],
        );
      },
    );
  }

  String _statusLabel(String status) => switch (status) {
        'pending_payment' => 'Menunggu pembayaran',
        'pending_verification' => 'Menunggu verifikasi',
        'needs_review' => 'Perlu diperiksa',
        'rejected' => 'Ditolak',
        'expired' => 'Kedaluwarsa',
        _ => 'Terverifikasi',
      };

  String _methodLabel(String? method) => switch (method) {
        'cash' => 'Tunai',
        'transfer' => 'Transfer',
        'qris' => 'QRIS',
        _ => 'Metode belum tercatat',
      };
}

class _DonationInfoCard extends StatelessWidget {
  const _DonationInfoCard({
    required this.donation,
    required this.memberName,
    required this.statusLabel,
    required this.methodLabel,
    required this.payable,
  });

  final Donation donation;
  final String? memberName;
  final String statusLabel;
  final String methodLabel;
  final double payable;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memberName != null) ...[
              _DetailLine(label: 'Anggota', value: memberName!),
              const SizedBox(height: AppSpacing.xs),
            ],
            _DetailLine(label: 'Status', value: statusLabel),
            const SizedBox(height: AppSpacing.xs),
            _DetailLine(label: 'Metode', value: methodLabel),
            const SizedBox(height: AppSpacing.xs),
            _DetailLine(
                label: 'Nominal donasi',
                value: Formatters.formatCurrency(donation.amount)),
            if (donation.uniqueCode != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(
                  label: 'Kode unik',
                  value: donation.uniqueCode!.toString().padLeft(3, '0')),
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(
                  label: 'Nominal pembayaran',
                  value: Formatters.formatCurrency(payable)),
              Align(
                alignment: Alignment.centerRight,
                // child: IconButton(
                //   tooltip: 'Salin nominal pembayaran',
                //   onPressed: () => Clipboard.setData(
                //       ClipboardData(text: payable.toInt().toString())),
                //   icon: const Icon(Icons.copy_rounded, size: 18),
                // ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            _DetailLine(
                label: 'Dilaporkan',
                value: Formatters.formatDate(donation.donatedAt)),
            if (donation.receivedAmount != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(
                  label: 'Diterima admin',
                  value: Formatters.formatCurrency(donation.receivedAmount!)),
            ],
            if (donation.paymentReference?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(
                  label: 'Referensi', value: donation.paymentReference!),
            ],
          ],
        ),
      );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(text,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
      );
}

class _DonationReviewResult {
  const _DonationReviewResult({this.receivedAmount, this.note});
  final double? receivedAmount;
  final String? note;
}

class _DonationReviewDialog extends StatefulWidget {
  const _DonationReviewDialog(
      {required this.status, required this.initialAmount});
  final String status;
  final double initialAmount;

  @override
  State<_DonationReviewDialog> createState() => _DonationReviewDialogState();
}

class _DonationReviewDialogState extends State<_DonationReviewDialog> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.initialAmount.toInt().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verifying = widget.status == 'verified';
    final title = verifying
        ? 'Konfirmasi dana diterima'
        : widget.status == 'needs_review'
            ? 'Tandai perlu diperiksa'
            : 'Tolak laporan donasi';
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (verifying)
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nominal diterima (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'Masukkan nominal yang diterima'
                        : null;
                  },
                ),
              if (verifying) const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText:
                      verifying ? 'Catatan (opsional)' : 'Alasan (wajib)',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    !verifying && (value == null || value.trim().isEmpty)
                        ? 'Alasan wajib diisi'
                        : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _DonationReviewResult(
                receivedAmount:
                    verifying ? double.parse(_amountController.text) : null,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
