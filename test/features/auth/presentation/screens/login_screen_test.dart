import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/auth/presentation/screens/login_screen.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

  testWidgets('renders login form correctly', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('BANI RASIJAN'), findsOneWidget);
    expect(find.text('Masuk dengan email'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Kirim Magic Link'), findsOneWidget);
    expect(
      find.text('Belum bergabung? Gunakan kode undangan.'),
      findsOneWidget,
    );
  });

  testWidgets('shows validation error when submitting empty email',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Kirim Magic Link'));
    await tester.pump();

    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    verifyNever(() => mockRepo.signInWithOtp(any()));
  });

  testWidgets('shows validation error when submitting invalid email',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextFormField), 'invalid-email');
    await tester.tap(find.text('Kirim Magic Link'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    verifyNever(() => mockRepo.signInWithOtp(any()));
  });

  testWidgets('calls signInWithOtp on valid email', (tester) async {
    when(() => mockRepo.signInWithOtp('user@example.com'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(buildWidget());

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('Kirim Magic Link'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.signInWithOtp('user@example.com')).called(1);
  });
}
