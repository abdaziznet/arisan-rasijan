import 'package:bani_rasijan/features/biometric/data/biometric_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BiometricPreferences preferences;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    preferences = BiometricPreferences();
  });

  group('BiometricPreferences', () {
    test('isBiometricEnabled defaults to false and saves correctly', () async {
      expect(await preferences.isBiometricEnabled(), isFalse);

      await preferences.setBiometricEnabled(true);
      expect(await preferences.isBiometricEnabled(), isTrue);

      await preferences.setBiometricEnabled(false);
      expect(await preferences.isBiometricEnabled(), isFalse);
    });

    test('getAutoLockTimeoutMinutes defaults to 1 and saves correctly', () async {
      expect(await preferences.getAutoLockTimeoutMinutes(), equals(1));

      await preferences.setAutoLockTimeoutMinutes(5);
      expect(await preferences.getAutoLockTimeoutMinutes(), equals(5));
    });

    test('lastBackgroundTime handles save, read, and clear', () async {
      expect(await preferences.getLastBackgroundTime(), equals(0));

      const testTime = 1700000000000;
      await preferences.setLastBackgroundTime(testTime);
      expect(await preferences.getLastBackgroundTime(), equals(testTime));

      await preferences.clearLastBackgroundTime();
      expect(await preferences.getLastBackgroundTime(), equals(0));
    });

    test('failedAttempts increments, reads, and resets', () async {
      expect(await preferences.getFailedAttempts(), equals(0));

      final first = await preferences.incrementFailedAttempts();
      expect(first, equals(1));
      expect(await preferences.getFailedAttempts(), equals(1));

      final second = await preferences.incrementFailedAttempts();
      expect(second, equals(2));
      expect(await preferences.getFailedAttempts(), equals(2));

      await preferences.resetFailedAttempts();
      expect(await preferences.getFailedAttempts(), equals(0));
    });

    test('promptOffered handles flag correctly', () async {
      expect(await preferences.isPromptOffered(), isFalse);

      await preferences.setPromptOffered(true);
      expect(await preferences.isPromptOffered(), isTrue);
    });

    test('clearAll removes all biometric preferences', () async {
      await preferences.setBiometricEnabled(true);
      await preferences.setAutoLockTimeoutMinutes(3);
      await preferences.incrementFailedAttempts();
      await preferences.setPromptOffered(true);

      await preferences.clearAll();

      expect(await preferences.isBiometricEnabled(), isFalse);
      expect(await preferences.getAutoLockTimeoutMinutes(), equals(1));
      expect(await preferences.getFailedAttempts(), equals(0));
      expect(await preferences.isPromptOffered(), isFalse);
    });
  });
}
