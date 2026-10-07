import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_components.dart';
import '../../../routing/app_router.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../biometric/presentation/providers/biometric_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (state) {
        // Beri sedikit waktu agar transisi tidak terlalu cepat
        Future.microtask(() => _handleNavigation(ref, context, state.session));
        return _buildSplashScreenUI(context);
      },
      loading: () => _buildSplashScreenUI(context, withLoading: true),
      error: (error, stackTrace) {
        // Jika ada error (misal, token tidak valid), arahkan ke login
        Future.microtask(() =>
            Navigator.pushReplacementNamed(context, AppRouter.login));
        return _buildSplashScreenUI(context);
      },
    );
  }

  Future<void> _handleNavigation(
    WidgetRef ref,
    BuildContext context,
    Session? session,
  ) async {
    if (session != null) {
      // Session valid — cek apakah profil sudah ada
      final hasProfile = await ref.read(authRepositoryProvider).hasProfile();
      if (!context.mounted) return;

      if (!hasProfile) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.profileCompletion,
        );
        return;
      }

      // Cek apakah kunci biometrik aktif
      final isBioEnabled =
          await ref.read(biometricControllerProvider.notifier).isBiometricEnabled();
      if (!context.mounted) return;

      if (isBioEnabled) {
        await ref.read(biometricControllerProvider.notifier).clearBackgroundTime();
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRouter.biometricLock,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.home,
        );
      }
    } else {
      // Tidak ada session, ke halaman login
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  Widget _buildSplashScreenUI(BuildContext context, {bool withLoading = false}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Semantics(
          label: 'BANI RASIJAN, Arisan Keluarga',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(
                size: AppLogoSize.hero,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('BANI RASIJAN', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Arisan Keluarga',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (withLoading) ...[
                const SizedBox(height: AppSpacing.xl),
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
