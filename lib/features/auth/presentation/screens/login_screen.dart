import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../../../../routing/app_router.dart';
import '../../../biometric/domain/biometric_state.dart';
import '../../../biometric/domain/biometric_type.dart';
import '../../../biometric/presentation/providers/biometric_providers.dart';
import '../../../biometric/presentation/widgets/biometric_activation_sheet.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _signInWithGoogle() {
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  Future<void> _signInWithBiometric() async {
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session == null) {
      AppSnackbar.show(
        context,
        'Sesi login telah berakhir. Silakan masuk kembali dengan Google.',
      );
      return;
    }

    final bioController = ref.read(biometricControllerProvider.notifier);
    await bioController.authenticateForLockScreen();
    final bioState = ref.read(biometricControllerProvider);

    if (bioState is BiometricAuthenticated && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isBioEnabledAsync = ref.watch(isBiometricEnabledProvider);
    final isCapableAsync = ref.watch(biometricCapabilityProvider);
    final primaryTypeAsync = ref.watch(biometricPrimaryTypeProvider);

    final isBioActive = (isBioEnabledAsync.valueOrNull ?? false) &&
        (isCapableAsync.valueOrNull ?? false);
    final primaryType =
        primaryTypeAsync.valueOrNull ?? AppBiometricType.fingerprint;

    ref.listen<AuthScreenState>(authControllerProvider, (_, state) async {
      if (state is AuthSuccess) {
        final repo = ref.read(authRepositoryProvider);
        final hasProfile = await repo.hasProfile();
        if (!context.mounted) return;

        if (!hasProfile) {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.profileCompletion,
          );
          return;
        }

        // Tawarkan aktivasi biometrik jika perangkat mendukung dan belum pernah ditawarkan
        final bioController = ref.read(biometricControllerProvider.notifier);
        final isCapable = await bioController.isDeviceCapable();
        final isOffered = await bioController.isPromptOffered();

        if (context.mounted && isCapable && !isOffered) {
          await BiometricActivationSheet.show(context);
        }

        if (!context.mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );
      } else if (state is AuthError) {
        AppSnackbar.show(context, state.message);
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadii.hero,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Selamat datang di',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'BANI RASIJAN',
                    textAlign: TextAlign.center,
                    style: AppTypography.display,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Arisan & Silaturahmi Keluarga',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.card,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Masuk Akun',
                          style: AppTypography.h3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gunakan akun Google yang terdaftar untuk melanjutkan.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.button,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.surface,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.g_mobiledata_rounded, size: 28),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Lanjut dengan Google',
                                          style: AppTypography.button.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        if (isBioActive) ...[
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _signInWithBiometric,
                              icon: Icon(
                                primaryType == AppBiometricType.face
                                    ? Icons.face_rounded
                                    : Icons.fingerprint_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Buka dengan ${primaryType.displayName}',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.button,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                AppRouter.invite,
                              ),
                      child: Text(
                        'Punya kode undangan baru?',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
