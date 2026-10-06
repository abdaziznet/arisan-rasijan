import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/biometric_type.dart';
import '../providers/biometric_providers.dart';

class BiometricActivationSheet extends ConsumerStatefulWidget {
  const BiometricActivationSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BiometricActivationSheet(),
    );
  }

  @override
  ConsumerState<BiometricActivationSheet> createState() =>
      _BiometricActivationSheetState();
}

class _BiometricActivationSheetState
    extends ConsumerState<BiometricActivationSheet> {
  bool _isLoading = false;

  Future<void> _handleEnable() async {
    setState(() => _isLoading = true);
    final controller = ref.read(biometricControllerProvider.notifier);
    final success = await controller.enableBiometric();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackbar.show(context, 'Kunci biometrik berhasil diaktifkan.');
      Navigator.of(context).pop(true);
    } else {
      AppSnackbar.show(
        context,
        'Gagal mengaktifkan biometrik. Silakan coba lagi nanti.',
      );
    }
  }

  Future<void> _handleDismiss() async {
    final controller = ref.read(biometricControllerProvider.notifier);
    await controller.markPromptOffered();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryTypeAsync = ref.watch(biometricPrimaryTypeProvider);
    final primaryType = primaryTypeAsync.valueOrNull ?? AppBiometricType.fingerprint;

    final iconData = primaryType == AppBiometricType.face
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;
    final typeName = primaryType.displayName;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sheet,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadii.small,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aktifkan Kunci $typeName?',
              textAlign: TextAlign.center,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Buka aplikasi lebih cepat dan aman menggunakan $typeName Anda tanpa harus login berulang.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildBenefitItem(
              Icons.speed_rounded,
              'Akses instan saat membuka aplikasi',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBenefitItem(
              Icons.lock_clock_rounded,
              'Otomatis terkunci saat aplikasi ditinggalkan',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBenefitItem(
              Icons.security_rounded,
              'Data biometrik tetap aman di perangkat Anda',
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleEnable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.button,
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.surface,
                        ),
                      )
                    : Text(
                        'Aktifkan Sekarang',
                        style: AppTypography.button.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _handleDismiss,
                child: Text(
                  'Nanti Saja',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadii.small,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.mdSm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
