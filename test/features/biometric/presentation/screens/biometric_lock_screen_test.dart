import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/biometric/data/biometric_preferences.dart';
import 'package:bani_rasijan/features/biometric/data/biometric_service.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_state.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_type.dart';
import 'package:bani_rasijan/features/biometric/presentation/providers/biometric_providers.dart';
import 'package:bani_rasijan/features/biometric/presentation/screens/biometric_lock_screen.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockBiometricService();
    mockAuthRepo = MockAuthRepository();
    preferences = BiometricPreferences();
  });

  Widget buildTestWidget() => ProviderScope(
        overrides: [
          biometricServiceProvider.overrideWithValue(mockService),
          biometricPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: BiometricLockScreen(),
        ),
      );

  group('BiometricLockScreen', () {
    testWidgets('renders lock screen elements properly', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => const BiometricAuthSuccess());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('BANI RASIJAN'), findsOneWidget);
      expect(find.text('Aplikasi Terkunci'), findsOneWidget);
      expect(find.text('Pindai Ulang'), findsOneWidget);
      expect(find.text('Masuk dengan Akun Google'), findsOneWidget);
    });

    testWidgets('displays error message and remaining attempts on auth failure', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthFailed(
          errorMessage: 'Sidik jari tidak cocok',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sidik jari tidak cocok'), findsOneWidget);
      expect(find.text('Percobaan tersisa: 2 kali'), findsOneWidget);
    });

    testWidgets('fallback button calls signOut and navigates to login', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer(
        (_) async => const BiometricAuthFailed(
          errorMessage: 'Canceled',
          isUserCanceled: true,
        ),
      );
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk dengan Akun Google'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.signOut()).called(1);
    });
  });
}
