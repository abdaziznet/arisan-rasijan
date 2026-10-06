import 'package:bani_rasijan/features/biometric/data/biometric_service.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_state.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricService service;

  setUpAll(() {
    registerFallbackValue(
      const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  });

  setUp(() {
    mockAuth = MockLocalAuthentication();
    service = BiometricService(auth: mockAuth);
  });

  group('BiometricService', () {
    test('isHardwareSupported returns true when supported', () async {
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await service.isHardwareSupported();
      expect(result, isTrue);
    });

    test('isHardwareSupported returns false on PlatformException', () async {
      when(() => mockAuth.isDeviceSupported())
          .thenThrow(PlatformException(code: 'Error', message: 'Failed'));

      final result = await service.isHardwareSupported();
      expect(result, isFalse);
    });

    test('hasEnrolledBiometrics returns true when canCheck and biometrics available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await service.hasEnrolledBiometrics();
      expect(result, isTrue);
    });

    test('hasEnrolledBiometrics returns false when no biometrics enrolled', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => <BiometricType>[]);

      final result = await service.hasEnrolledBiometrics();
      expect(result, isFalse);
    });

    test('getPrimaryBiometricType returns face when available', () async {
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      final result = await service.getPrimaryBiometricType();
      expect(result, equals(AppBiometricType.face));
    });

    test('getPrimaryBiometricType returns fingerprint when available', () async {
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await service.getPrimaryBiometricType();
      expect(result, equals(AppBiometricType.fingerprint));
    });

    test('authenticate returns success when local_auth returns true', () async {
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await service.authenticate(localizedReason: 'Test');
      expect(result, isA<BiometricAuthSuccess>());
    });

    test('authenticate returns failed when local_auth returns false', () async {
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);

      final result = await service.authenticate(localizedReason: 'Test');
      expect(result, isA<BiometricAuthFailed>());
    });

    test('authenticate returns locked out on LockedOut PlatformException', () async {
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'LockedOut', message: 'Locked out'));

      final result = await service.authenticate(localizedReason: 'Test');
      expect(result, isA<BiometricAuthFailed>());
      expect((result as BiometricAuthFailed).isLockedOut, isTrue);
    });

    test('authenticate returns not available when hardware unsupported', () async {
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await service.authenticate(localizedReason: 'Test');
      expect(result, isA<BiometricAuthNotAvailable>());
    });
  });
}
