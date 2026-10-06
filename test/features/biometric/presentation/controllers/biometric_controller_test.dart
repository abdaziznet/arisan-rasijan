import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/biometric/data/biometric_preferences.dart';
import 'package:bani_rasijan/features/biometric/data/biometric_service.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_state.dart';
import 'package:bani_rasijan/features/biometric/presentation/providers/biometric_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBiometricService extends Mock implements IBiometricService {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockBiometricService mockService;
  late MockAuthRepository mockAuthRepo;
  late BiometricPreferences preferences;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockBiometricService();
    mockAuthRepo = MockAuthRepository();
    preferences = BiometricPreferences();

    container = ProviderContainer(
      overrides: [
        biometricServiceProvider.overrideWithValue(mockService),
        biometricPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BiometricController', () {
    test('isDeviceCapable checks hardware and enrolled status', () async {
      when(() => mockService.isHardwareSupported()).thenAnswer((_) async => true);
      when(() => mockService.hasEnrolledBiometrics()).thenAnswer((_) async => true);

      final controller = container.read(biometricControllerProvider.notifier);
      final isCapable = await controller.isDeviceCapable();

      expect(isCapable, isTrue);
      verify(() => mockService.isHardwareSupported()).called(1);
      verify(() => mockService.hasEnrolledBiometrics()).called(1);
    });

    test('enableBiometric returns true and sets prefs when auth succeeds', () async {
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => const BiometricAuthSuccess());

      final controller = container.read(biometricControllerProvider.notifier);
      final result = await controller.enableBiometric();

      expect(result, isTrue);
      expect(await preferences.isBiometricEnabled(), isTrue);
      expect(await preferences.isPromptOffered(), isTrue);
    });

    test('enableBiometric returns false when auth fails', () async {
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthFailed(errorMessage: 'Failed'),
      );

      final controller = container.read(biometricControllerProvider.notifier);
      final result = await controller.enableBiometric();

      expect(result, isFalse);
      expect(await preferences.isBiometricEnabled(), isFalse);
    });

    test('disableBiometric updates preference to false', () async {
      await preferences.setBiometricEnabled(true);
      final controller = container.read(biometricControllerProvider.notifier);

      await controller.disableBiometric();
      expect(await preferences.isBiometricEnabled(), isFalse);
    });

    test('shouldLockOnResume returns true when elapsed >= timeout', () async {
      await preferences.setBiometricEnabled(true);
      await preferences.setAutoLockTimeoutMinutes(1);

      // Set last background time 2 minutes ago
      final twoMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch;
      await preferences.setLastBackgroundTime(twoMinutesAgo);

      final controller = container.read(biometricControllerProvider.notifier);
      final shouldLock = await controller.shouldLockOnResume();

      expect(shouldLock, isTrue);
    });

    test('shouldLockOnResume returns false when elapsed < timeout', () async {
      await preferences.setBiometricEnabled(true);
      await preferences.setAutoLockTimeoutMinutes(2);

      // Set last background time 30 seconds ago
      final thirtySecAgo =
          DateTime.now().subtract(const Duration(seconds: 30)).millisecondsSinceEpoch;
      await preferences.setLastBackgroundTime(thirtySecAgo);

      final controller = container.read(biometricControllerProvider.notifier);
      final shouldLock = await controller.shouldLockOnResume();

      expect(shouldLock, isFalse);
    });

    test('authenticateForLockScreen sets BiometricAuthenticated and clears last background time on success', () async {
      await preferences.setLastBackgroundTime(1700000000000);
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => const BiometricAuthSuccess());

      final controller = container.read(biometricControllerProvider.notifier);
      await controller.authenticateForLockScreen();

      expect(
        container.read(biometricControllerProvider),
        isA<BiometricAuthenticated>(),
      );
      expect(await preferences.getFailedAttempts(), equals(0));
      expect(await preferences.getLastBackgroundTime(), equals(0));
    });

    test('recordBackground does not record time if isAuthenticating is true', () async {
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async {
        final controller = container.read(biometricControllerProvider.notifier);
        expect(controller.isAuthenticating, isTrue);
        await controller.recordBackground();
        return const BiometricAuthSuccess();
      });

      final controller = container.read(biometricControllerProvider.notifier);
      await controller.authenticateForLockScreen();

      expect(await preferences.getLastBackgroundTime(), equals(0));
    });

    test('authenticateForLockScreen increments failed attempts and sets BiometricFailed', () async {
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthFailed(
          errorMessage: 'Sidik jari tidak cocok',
        ),
      );

      final controller = container.read(biometricControllerProvider.notifier);
      await controller.authenticateForLockScreen();

      final state = container.read(biometricControllerProvider);
      expect(state, isA<BiometricFailed>());
      expect((state as BiometricFailed).remainingAttempts, equals(2));
      expect(await preferences.getFailedAttempts(), equals(1));
    });

    test('authenticateForLockScreen locks out on 3 consecutive failures and calls signOut', () async {
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthFailed(
          errorMessage: 'Sidik jari tidak cocok',
        ),
      );

      // Pre-set 2 failed attempts
      await preferences.incrementFailedAttempts();
      await preferences.incrementFailedAttempts();

      final controller = container.read(biometricControllerProvider.notifier);
      await controller.authenticateForLockScreen();

      final state = container.read(biometricControllerProvider);
      expect(state, isA<BiometricLockedOut>());
      verify(() => mockAuthRepo.signOut()).called(1);
    });
  });
}
