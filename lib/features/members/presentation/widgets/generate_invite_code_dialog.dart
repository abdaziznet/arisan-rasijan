import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../providers/members_providers.dart';

class GenerateInviteCodeDialog extends ConsumerStatefulWidget {
  const GenerateInviteCodeDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const GenerateInviteCodeDialog(),
      );

  @override
  ConsumerState<GenerateInviteCodeDialog> createState() =>
      _GenerateInviteCodeDialogState();
}

class _GenerateInviteCodeDialogState
    extends ConsumerState<GenerateInviteCodeDialog> {
  final _customCodeController = TextEditingController();
  int _maxUses = 1;
  int _expiresDays = 30;
  bool _isLoading = false;
  String? _generatedCode;

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    try {
      final code = await ref
          .read(membersControllerProvider.notifier)
          .generateInviteCode(
            customCode: _customCodeController.text.trim().isEmpty
                ? null
                : _customCodeController.text.trim(),
            maxUses: _maxUses,
            expiresDays: _expiresDays,
          );

      if (mounted) {
        setState(() {
          _generatedCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Gagal membuat kode undangan. Pastikan Anda adalah Admin.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    AppSnackbar.show(context, 'Kode $_generatedCode disalin ke papan klip!');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadii.small,
            ),
            child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Buat Kode Undangan', style: AppTypography.h3),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_generatedCode == null) ...[
              Text(
                'Buat kode undangan baru untuk keluarga yang akan bergabung.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _customCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Kustom (Opsional)',
                  hintText: 'Contoh: BANI2026',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                initialValue: _maxUses,
                decoration: const InputDecoration(
                  labelText: 'Batas Penggunaan',
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Anggota')),
                  DropdownMenuItem(value: 5, child: Text('5 Anggota')),
                  DropdownMenuItem(value: 10, child: Text('10 Anggota')),
                  DropdownMenuItem(value: 50, child: Text('50 Anggota')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _maxUses = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                initialValue: _expiresDays,
                decoration: const InputDecoration(
                  labelText: 'Masa Berlaku',
                ),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 Hari')),
                  DropdownMenuItem(value: 30, child: Text('30 Hari')),
                  DropdownMenuItem(value: 90, child: Text('90 Hari')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _expiresDays = val);
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadii.card,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KODE UNDANGAN BERHASIL DIBUAT',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      _generatedCode!,
                      style: AppTypography.display.copyWith(
                        color: AppColors.primaryDark,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Bisa digunakan untuk $_maxUses orang (Berlaku $_expiresDays hari).',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Salin Kode Undangan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _copyToClipboard,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_generatedCode == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Buat Kode'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ],
    );
  }
}
