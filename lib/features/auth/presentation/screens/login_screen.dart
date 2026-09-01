import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../../../../routing/app_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthScreenState>(authControllerProvider, (_, state) async {
      if (state is AuthSuccess) {
        final repo = ref.read(authRepositoryProvider);
        final hasProfile = await repo.hasProfile();
        if (!context.mounted) return;

        if (hasProfile) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.home,
            (route) => false,
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.profileCompletion,
          );
        }
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
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.g_mobiledata_rounded, size: 28),
                                        SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Lanjut dengan Google',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
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
