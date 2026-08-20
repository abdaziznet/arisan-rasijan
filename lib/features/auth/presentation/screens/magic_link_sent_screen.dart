import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../providers/auth_providers.dart';

class MagicLinkSentScreen extends ConsumerStatefulWidget {
  const MagicLinkSentScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<MagicLinkSentScreen> createState() =>
      _MagicLinkSentScreenState();
}

class _MagicLinkSentScreenState extends ConsumerState<MagicLinkSentScreen> {
  static const _cooldown = 60;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _remaining = _cooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).signInWithOtp(widget.email);
      if (mounted) {
        AppSnackbar.show(context, 'Link baru telah dikirim.');
        _startCooldown();
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, 'Gagal mengirim ulang. Coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen auth state — jika user klik magic link dan berhasil, navigasi
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.home,
            (_) => false,
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authControllerProvider.notifier).reset();
            Navigator.pushReplacementNamed(context, AppRouter.login);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Cek email Anda',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Magic link telah dikirim ke:',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.email,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Buka email dan klik link untuk masuk.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_remaining > 0)
                    Text(
                      'Kirim ulang dalam $_remaining detik',
                      style: AppTypography.caption,
                    )
                  else
                    TextButton(
                      onPressed: _resend,
                      child: const Text('Kirim ulang link'),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).reset();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRouter.login,
                      );
                    },
                    child: const Text('Ganti email'),
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
