import 'package:bani_rasijan/features/biometric/data/biometric_preferences.dart';
import 'package:bani_rasijan/features/biometric/data/biometric_service.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_state.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_type.dart';
import 'package:bani_rasijan/features/biometric/presentation/providers/biometric_providers.dart';
import 'package:bani_rasijan/features/biometric/presentation/widgets/biometric_activation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBiometricService extends Mock implements IBiometricService {}

void main() {
  late MockBiometricService mockService;
  late BiometricPreferences preferences;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockBiometricService();
    preferences = BiometricPreferences();
  });

  Widget buildTestWidget() => ProviderScope(
        overrides: [
          biometricServiceProvider.overrideWithValue(mockService),
          biometricPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BiometricActivationSheet(),
          ),
        ),
      );

  group('BiometricActivationSheet', () {
    testWidgets('renders title, benefits, and action buttons', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Kunci Sidik Jari?'), findsOneWidget);
      expect(find.text('Aktifkan Sekarang'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.text('Akses instan saat membuka aplikasi'), findsOneWidget);
    });

    testWidgets('renders Face ID title when primary type is face', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.face);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Kunci Face ID?'), findsOneWidget);
    });

    testWidgets('enables biometric when Aktifkan Sekarang is tapped', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);
      when(
        () => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => const BiometricAuthSuccess());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aktifkan Sekarang'));
      await tester.pumpAndSettle();

      expect(await preferences.isBiometricEnabled(), isTrue);
    });

    testWidgets('marks prompt offered when Nanti Saja is tapped', (tester) async {
      when(() => mockService.getPrimaryBiometricType())
          .thenAnswer((_) async => AppBiometricType.fingerprint);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nanti Saja'));
      await tester.pumpAndSettle();

      expect(await preferences.isPromptOffered(), isTrue);
      expect(await preferences.isBiometricEnabled(), isFalse);
    });
  });
}
