import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../domain/biometric_type.dart';
import '../providers/biometric_providers.dart';

class BiometricSettingsTile extends ConsumerWidget {
  const BiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final isEnabledAsync = ref.watch(isBiometricEnabledProvider);
    final timeoutAsync = ref.watch(autoLockTimeoutMinutesProvider);
    final primaryTypeAsync = ref.watch(biometricPrimaryTypeProvider);

    return capabilityAsync.when(
      data: (isCapable) {
        if (!isCapable) return const SizedBox.shrink();

        final isEnabled = isEnabledAsync.valueOrNull ?? false;
        final timeoutMinutes = timeoutAsync.valueOrNull ?? 1;
        final primaryType =
            primaryTypeAsync.valueOrNull ?? AppBiometricType.fingerprint;

        final iconData = primaryType == AppBiometricType.face
            ? Icons.face_rounded
            : Icons.fingerprint_rounded;

        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.card,
            side: BorderSide(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Keamanan & Kunci Aplikasi',
                        style: AppTypography.h3),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Amankan akses ke aplikasi dengan kunci layar lokal.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(iconData, color: AppColors.primary),
                  title: Text(
                    'Kunci ${primaryType.displayName}',
                    style: AppTypography.bodyLarge,
                  ),
                  subtitle: Text(
                    'Kunci aplikasi saat ditutup atau ditinggalkan',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  value: isEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) async {
                    final controller =
                        ref.read(biometricControllerProvider.notifier);
                    if (value) {
                      final success = await controller.enableBiometric();
                      if (context.mounted) {
                        if (success) {
                          ref.invalidate(isBiometricEnabledProvider);
                          AppSnackbar.show(
                            context,
                            'Kunci ${primaryType.displayName} diaktifkan.',
                          );
                        } else {
                          AppSnackbar.show(
                            context,
                            'Verifikasi biometrik gagal atau dibatalkan.',
                          );
                        }
                      }
                    } else {
                      await controller.disableBiometric();
                      ref.invalidate(isBiometricEnabledProvider);
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          'Kunci ${primaryType.displayName} dinonaktifkan.',
                        );
                      }
                    }
                  },
                ),
                if (isEnabled) ...[
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.timer_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Waktu Kunci Otomatis',
                      style: AppTypography.body,
                    ),
                    subtitle: Text(
                      _getTimeoutLabel(timeoutMinutes),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => _showTimeoutPicker(
                      context,
                      ref,
                      timeoutMinutes,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getTimeoutLabel(int minutes) {
    switch (minutes) {
      case 0:
        return 'Langsung saat keluar';
      case 1:
        return 'Setelah 1 menit (Rekomendasi)';
      case 2:
        return 'Setelah 2 menit';
      case 3:
        return 'Setelah 3 menit';
      case 5:
        return 'Setelah 5 menit';
      default:
        return 'Setelah $minutes menit';
    }
  }

  void _showTimeoutPicker(
    BuildContext context,
    WidgetRef ref,
    int currentTimeout,
  ) {
    final options = [
      (0, 'Langsung saat keluar'),
      (1, 'Setelah 1 menit (Rekomendasi)'),
      (2, 'Setelah 2 menit'),
      (3, 'Setelah 3 menit'),
      (5, 'Setelah 5 menit'),
    ];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheet,
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: AppRadii.small,
                    ),
                  ),
                ),
                const Text(
                  'Pilih Waktu Kunci Otomatis',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ...options.map((option) {
                  final (value, label) = option;
                  final isSelected = value == currentTimeout;

                  return ListTile(
                    title: Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () async {
                      final controller =
                          ref.read(biometricControllerProvider.notifier);
                      await controller.setAutoLockTimeoutMinutes(value);
                      ref.invalidate(autoLockTimeoutMinutesProvider);
                      if (bottomSheetContext.mounted) {
                        Navigator.of(bottomSheetContext).pop();
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
