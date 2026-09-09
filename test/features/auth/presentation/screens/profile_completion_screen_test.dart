import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSession extends Mock implements Session {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockSession mockSession;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockSession = MockSession();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('test-user-id');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Ahmad Test'});
    when(() => mockSession.user).thenReturn(mockUser);
  });

  Widget buildWidget() => ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          currentSessionProvider.overrideWith((ref) => Stream.value(mockSession)),
          currentMemberProfileProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: ProfileCompletionScreen(),
        ),
      );

  testWidgets('renders invite code & profile fields correctly for new user',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Aktivasi Anggota Keluarga'), findsOneWidget);
    expect(find.text('Kode Undangan *'), findsOneWidget);
    expect(find.text('Nama Lengkap *'), findsOneWidget);
    expect(find.text('Aktifkan & Bergabung'), findsOneWidget);
  });

  testWidgets('validates required fields when submitted empty', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Clear auto-populated name if any and submit
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), ''); // Kode undangan
    await tester.enterText(textFields.at(1), ''); // Nama lengkap
    await tester.ensureVisible(find.text('Aktifkan & Bergabung'));
    await tester.tap(find.text('Aktifkan & Bergabung'));
    await tester.pumpAndSettle();

    expect(find.text('Kode undangan tidak boleh kosong'), findsOneWidget);
    expect(find.text('Nama lengkap tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('calls redeemInviteCodeAndCreateProfile on valid submit',
      (tester) async {
    when(
      () => mockAuthRepo.redeemInviteCodeAndCreateProfile(
        code: 'BANI2026',
        fullName: 'Ahmad Rasijan',
        phoneNumber: '08123456789',
        address: 'Yogyakarta',
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'BANI2026');
    await tester.enterText(textFields.at(1), 'Ahmad Rasijan');
    await tester.enterText(textFields.at(2), '08123456789');
    await tester.enterText(textFields.at(3), 'Yogyakarta');

    await tester.ensureVisible(find.text('Aktifkan & Bergabung'));
    await tester.tap(find.text('Aktifkan & Bergabung'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuthRepo.redeemInviteCodeAndCreateProfile(
        code: 'BANI2026',
        fullName: 'Ahmad Rasijan',
        phoneNumber: '08123456789',
        address: 'Yogyakarta',
      ),
    ).called(1);
  });
}
