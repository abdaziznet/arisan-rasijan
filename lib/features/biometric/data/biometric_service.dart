import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/biometric_state.dart';
import '../domain/biometric_type.dart';

abstract interface class IBiometricService {
  Future<bool> isHardwareSupported();
  Future<bool> hasEnrolledBiometrics();
  Future<List<AppBiometricType>> getAvailableBiometrics();
  Future<AppBiometricType> getPrimaryBiometricType();
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = true,
  });
}

class BiometricService implements IBiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isHardwareSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      log('Biometric isHardwareSupported error: $e');
      return false;
    } catch (e) {
      log('Biometric unexpected isHardwareSupported error: $e');
      return false;
    }
  }

  @override
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      log('Biometric hasEnrolledBiometrics error: $e');
      return false;
    } catch (e) {
      log('Biometric unexpected hasEnrolledBiometrics error: $e');
      return false;
    }
  }

  @override
  Future<List<AppBiometricType>> getAvailableBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.map(_mapBiometricType).toList();
    } on PlatformException catch (e) {
      log('Biometric getAvailableBiometrics error: $e');
      return [AppBiometricType.none];
    } catch (e) {
      log('Biometric unexpected getAvailableBiometrics error: $e');
      return [AppBiometricType.none];
    }
  }

  @override
  Future<AppBiometricType> getPrimaryBiometricType() async {
    final available = await getAvailableBiometrics();
    if (available.contains(AppBiometricType.face)) {
      return AppBiometricType.face;
    }
    if (available.contains(AppBiometricType.fingerprint)) {
      return AppBiometricType.fingerprint;
    }
    if (available.contains(AppBiometricType.iris)) {
      return AppBiometricType.iris;
    }
    return available.isNotEmpty ? available.first : AppBiometricType.none;
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final isSupported = await isHardwareSupported();
      if (!isSupported) {
        return const BiometricAuthNotAvailable(
          'Perangkat tidak mendukung autentikasi biometrik.',
        );
      }

      final hasBiometrics = await hasEnrolledBiometrics();
      if (!hasBiometrics) {
        return const BiometricAuthNotAvailable(
          'Belum ada biometrik yang didaftarkan pada perangkat ini.',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          useErrorDialogs: false,
        ),
      );

      if (authenticated) {
        return const BiometricAuthSuccess();
      } else {
        return const BiometricAuthFailed(
          errorMessage: 'Verifikasi biometrik tidak cocok atau dibatalkan.',
          isUserCanceled: true,
        );
      }
    } on PlatformException catch (e) {
      log('Biometric authenticate PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthFailed(
          errorMessage: 'Sensor biometrik terkunci sementara karena terlalu banyak percobaan.',
          isLockedOut: true,
        );
      }
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet') {
        return BiometricAuthNotAvailable(e.message ?? 'Biometrik tidak tersedia.');
      }
      if (e.code == 'UserCanceled' || e.code == 'AuthInProgress') {
        return const BiometricAuthFailed(
          errorMessage: 'Verifikasi dibatalkan oleh pengguna.',
          isUserCanceled: true,
        );
      }
      return BiometricAuthFailed(
        errorMessage: e.message ?? 'Gagal memverifikasi biometrik.',
      );
    } catch (e) {
      log('Biometric unexpected authenticate error: $e');
      return const BiometricAuthFailed(
        errorMessage: 'Terjadi kesalahan sistem saat memverifikasi biometrik.',
      );
    }
  }

  AppBiometricType _mapBiometricType(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return AppBiometricType.face;
      case BiometricType.fingerprint:
      case BiometricType.strong:
      case BiometricType.weak:
        return AppBiometricType.fingerprint;
      case BiometricType.iris:
        return AppBiometricType.iris;
    }
  }
}
