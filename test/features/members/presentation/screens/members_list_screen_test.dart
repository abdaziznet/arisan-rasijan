import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/members/presentation/screens/members_list_screen.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMembersRepository extends Mock implements MembersRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockMembersRepository mockMembersRepo;
  late MockAuthRepository mockAuthRepo;

  const sampleMembers = [
    MemberModel(
      id: 'm-1',
      fullName: 'Ahmad Rasijan',
      role: 'admin',
      phoneNumber: '0812345678',
    ),
    MemberModel(
      id: 'm-2',
      fullName: 'Budi Rasijan',
      role: 'member',
      isActive: false,
    ),
  ];

  setUp(() {
    mockMembersRepo = MockMembersRepository();
    mockAuthRepo = MockAuthRepository();
    when(() => mockMembersRepo.getMembers())
        .thenAnswer((_) async => sampleMembers);
    when(() => mockAuthRepo.currentSession).thenReturn(null);
  });

  Widget buildWidget() => ProviderScope(
        overrides: [
          membersRepositoryProvider.overrideWithValue(mockMembersRepo),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: MembersListScreen(),
        ),
      );

  testWidgets('renders list of members with badges', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Anggota Keluarga'), findsOneWidget);
    expect(find.text('Ahmad Rasijan'), findsOneWidget);
    expect(find.text('Budi Rasijan'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Anggota'), findsOneWidget);
    expect(find.text('Nonaktif'), findsNWidgets(2));
  });

  testWidgets('filters members list by search query', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Budi');
    await tester.pumpAndSettle();

    expect(find.text('Budi Rasijan'), findsOneWidget);
    expect(find.text('Ahmad Rasijan'), findsNothing);
  });
}
