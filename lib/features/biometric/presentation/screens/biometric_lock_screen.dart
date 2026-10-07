import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_components.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/biometric_state.dart';
import '../../domain/biometric_type.dart';
import '../providers/biometric_providers.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAuthentication();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    ref.read(biometricControllerProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _triggerAuthentication() async {
    final controller = ref.read(biometricControllerProvider.notifier);
    if (controller.isAuthenticating) return;
    await controller.authenticateForLockScreen();
  }

  Future<void> _fallbackToGoogleLogin() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biometricControllerProvider);
    final primaryTypeAsync = ref.watch(biometricPrimaryTypeProvider);
    final primaryType =
        primaryTypeAsync.valueOrNull ?? AppBiometricType.fingerprint;

    ref.listen<BiometricState>(biometricControllerProvider, (_, next) {
      if (next is BiometricAuthenticated) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        }
      } else if (next is BiometricFailed) {
        if (!next.isUserCanceled) {
          _shakeController.forward(from: 0.0);
        }
      } else if (next is BiometricLockedOut) {
        AppSnackbar.show(context, next.message);
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.login,
          (route) => false,
        );
      }
    });

    final isAuthenticating = state is BiometricAuthenticating;
    final isFailed = state is BiometricFailed;
    final failedState = isFailed ? state : null;

    final iconData = primaryType == AppBiometricType.face
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                    const Center(
                      child: AppLogo(
                        size: AppLogoSize.large,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'BANI RASIJAN',
                      textAlign: TextAlign.center,
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Aplikasi Terkunci',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadii.card,
                          border: Border.all(
                            color: isFailed
                                ? AppColors.error
                                : AppColors.divider,
                            width: isFailed ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              primaryType.actionPrompt,
                              style: AppTypography.h3,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Gunakan ${primaryType.displayName} untuk membuka aplikasi',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            InkWell(
                              onTap: isAuthenticating
                                  ? null
                                  : _triggerAuthentication,
                              borderRadius: BorderRadius.circular(48),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: isAuthenticating
                                    ? const Center(
                                        child: SizedBox.square(
                                          dimension: 32,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        iconData,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (failedState != null) ...[
                              Text(
                                failedState.errorMessage,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Percobaan tersisa: ${failedState.remainingAttempts} kali',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: isAuthenticating
                                    ? null
                                    : _triggerAuthentication,
                                icon: Icon(
                                  iconData,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                label: const Text('Pindai Ulang'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadii.button,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: TextButton.icon(
                        onPressed: _fallbackToGoogleLogin,
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 24,
                          color: AppColors.primaryDark,
                        ),
                        label: Text(
                          'Masuk dengan Akun Google',
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
      ),
    );
  }
}
