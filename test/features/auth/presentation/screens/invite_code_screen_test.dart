import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/auth/presentation/screens/invite_code_screen.dart';
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
          home: InviteCodeScreen(),
        ),
      );

  testWidgets('renders invite form correctly', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Bergabung dengan kode undangan'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Gunakan Kode'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Gunakan Kode'));
    await tester.pump();

    expect(find.text('Kode undangan tidak boleh kosong'), findsOneWidget);
    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('calls redeemInviteCode on valid input', (tester) async {
    when(
      () => mockRepo.redeemInviteCode(
        code: 'INVITE123',
        email: 'newuser@example.com',
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildWidget());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'INVITE123');
    await tester.enterText(fields.at(1), 'newuser@example.com');
    await tester.tap(find.text('Gunakan Kode'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.redeemInviteCode(
        code: 'INVITE123',
        email: 'newuser@example.com',
      ),
    ).called(1);
  });
}
