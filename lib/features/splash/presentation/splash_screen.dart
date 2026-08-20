import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routing/app_router.dart';
import '../../auth/presentation/providers/auth_providers.dart';

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
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          hasProfile ? AppRouter.home : AppRouter.profileCompletion,
        );
      }
    } else {
      // Tidak ada session, ke halaman login
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  Widget _buildSplashScreenUI(BuildContext context, {bool withLoading = false}) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'BANI RASIJAN, Arisan Keluarga',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (withLoading)
                const CircularProgressIndicator()
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 42),
                ),
              const SizedBox(height: AppSpacing.lg),
              const Text('BANI RASIJAN', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              const Text('Arisan Keluarga', style: AppTypography.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
