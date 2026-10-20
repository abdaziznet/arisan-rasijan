import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/auth/presentation/screens/login_screen.dart';
import 'package:bani_rasijan/features/biometric/domain/biometric_type.dart';
import 'package:bani_rasijan/features/biometric/presentation/providers/biometric_providers.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Widget buildWidget() => ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: LoginScreen(),
        ),
      );

  testWidgets('renders login screen with Google Sign-In button', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('BANI RASIJAN'), findsOneWidget);
    expect(find.text('Lanjut dengan Google'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('shows biometric icon beside Google button when enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          isBiometricEnabledProvider.overrideWith((ref) async => true),
          biometricCapabilityProvider.overrideWith((ref) async => true),
          biometricPrimaryTypeProvider
              .overrideWith((ref) async => AppBiometricType.fingerprint),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final googleButton = tester.getRect(find.byType(ElevatedButton));
    final biometricButton = tester.getRect(find.byType(OutlinedButton));
    expect(find.text('Lanjut dengan Google'), findsOneWidget);
    expect(find.textContaining('Buka dengan'), findsNothing);
    expect(biometricButton.height, googleButton.height);
    expect(biometricButton.top, googleButton.top);
    expect(biometricButton.left, greaterThan(googleButton.right));
    expect(find.byTooltip('Masuk dengan Sidik Jari'), findsOneWidget);
  });

  testWidgets('triggers signInWithGoogle when Google button is tapped', (tester) async {
    final mockResponse = MockAuthResponse();
    when(() => mockRepo.signInWithGoogle()).thenAnswer((_) async => mockResponse);
    when(() => mockRepo.hasProfile()).thenAnswer((_) async => true);

    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.signInWithGoogle()).called(1);
  });
}
