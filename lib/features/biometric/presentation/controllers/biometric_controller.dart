import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/biometric_preferences.dart';
import '../../data/biometric_service.dart';
import '../../domain/biometric_state.dart';
import '../../domain/biometric_type.dart';
import '../providers/biometric_providers.dart';

class BiometricController extends Notifier<BiometricState> {
  static const int maxFailedAttempts = 3;

  bool _isAuthenticating = false;
  bool get isAuthenticating =>
      _isAuthenticating || state is BiometricAuthenticating;

  @override
  BiometricState build() => const BiometricInitial();

  IBiometricService get _service => ref.read(biometricServiceProvider);
  BiometricPreferences get _prefs => ref.read(biometricPreferencesProvider);

  Future<bool> isDeviceCapable() async {
    final supported = await _service.isHardwareSupported();
    if (!supported) return false;
    return _service.hasEnrolledBiometrics();
  }

  Future<AppBiometricType> getPrimaryType() => _service.getPrimaryBiometricType();

  Future<bool> isBiometricEnabled() => _prefs.isBiometricEnabled();

  Future<int> getAutoLockTimeoutMinutes() => _prefs.getAutoLockTimeoutMinutes();

  Future<void> setAutoLockTimeoutMinutes(int minutes) async {
    await _prefs.setAutoLockTimeoutMinutes(minutes);
  }

  Future<bool> enableBiometric() async {
    if (_isAuthenticating) return false;
    _isAuthenticating = true;
    try {
      final result = await _service.authenticate(
        localizedReason:
            'Konfirmasi sidik jari atau Face ID untuk mengaktifkan kunci aplikasi.',
      );

      if (result is BiometricAuthSuccess) {
        await _prefs.setBiometricEnabled(true);
        await _prefs.setPromptOffered(true);
        await _prefs.resetFailedAttempts();
        await _prefs.clearLastBackgroundTime();
        return true;
      }
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> disableBiometric() async {
    await _prefs.setBiometricEnabled(false);
    await _prefs.resetFailedAttempts();
    await _prefs.clearLastBackgroundTime();
  }

  Future<void> markPromptOffered() async {
    await _prefs.setPromptOffered(true);
  }

  Future<bool> isPromptOffered() => _prefs.isPromptOffered();

  Future<void> recordBackground() async {
    if (isAuthenticating) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setLastBackgroundTime(now);
  }

  Future<void> clearBackgroundTime() => _prefs.clearLastBackgroundTime();

  Future<bool> shouldLockOnResume() async {
    if (isAuthenticating) return false;

    final isEnabled = await _prefs.isBiometricEnabled();
    if (!isEnabled) return false;

    final lastBackground = await _prefs.getLastBackgroundTime();
    if (lastBackground == 0) return false;

    final timeoutMinutes = await _prefs.getAutoLockTimeoutMinutes();
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - lastBackground;
    final timeoutMs = timeoutMinutes * 60 * 1000;

    return elapsedMs >= timeoutMs;
  }

  Future<void> authenticateForLockScreen() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    state = const BiometricAuthenticating();

    try {
      final result = await _service.authenticate(
        localizedReason: 'Buka kunci aplikasi BANI RASIJAN',
      );

      if (result is BiometricAuthSuccess) {
        await _prefs.resetFailedAttempts();
        await _prefs.clearLastBackgroundTime();
        state = const BiometricAuthenticated();
      } else if (result is BiometricAuthFailed) {
        if (result.isLockedOut) {
          state = const BiometricLockedOut(
            message:
                'Sensor biometrik terkunci. Masuk kembali menggunakan akun Google.',
          );
          await _handleLockout();
          return;
        }

        if (result.isUserCanceled) {
          final currentAttempts = await _prefs.getFailedAttempts();
          final remaining = maxFailedAttempts - currentAttempts;
          state = BiometricFailed(
            errorMessage: 'Verifikasi biometrik dibatalkan.',
            remainingAttempts: remaining > 0 ? remaining : 0,
            isUserCanceled: true,
          );
          return;
        }

        final attempts = await _prefs.incrementFailedAttempts();
        final remaining = maxFailedAttempts - attempts;

        if (attempts >= maxFailedAttempts) {
          state = const BiometricLockedOut(
            message:
                'Batas percobaan biometrik tercapai. Silakan masuk kembali dengan akun Google.',
          );
          await _handleLockout();
        } else {
          state = BiometricFailed(
            errorMessage: result.errorMessage,
            remainingAttempts: remaining,
          );
        }
      } else if (result is BiometricAuthNotAvailable) {
        state = BiometricUnavailable(reason: result.reason);
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> _handleLockout() async {
    await _prefs.resetFailedAttempts();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  void reset() {
    state = const BiometricInitial();
  }
}
