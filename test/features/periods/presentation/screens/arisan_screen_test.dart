import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository_provider.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/features/periods/presentation/screens/arisan_screen.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPeriodsRepository extends Mock implements PeriodsRepository {}

void main() {
  late MockPeriodsRepository mockPeriodsRepo;

  const admin = MemberModel(id: 'm-1', fullName: 'Ahmad Rasijan', role: 'admin');
  const member = MemberModel(id: 'm-2', fullName: 'Siti Rasijan', role: 'member');

  final activePeriod = PeriodModel(
    id: 'p-1',
    periodNumber: 1,
    eventDate: DateTime(2026, 10, 15),
    hostAddress: 'Jl. Melati No. 17',
    contributionAmount: 100000,
    status: 'upcoming',
    host: admin,
  );
  final completedPeriod = PeriodModel(
    id: 'p-0',
    periodNumber: 0,
    eventDate: DateTime(2026, 8, 15),
    hostAddress: 'Jl. Mawar No. 3',
    status: 'completed',
    host: member,
    winner: admin,
  );

  setUp(() {
    mockPeriodsRepo = MockPeriodsRepository();
    when(() => mockPeriodsRepo.getPeriods())
        .thenAnswer((_) async => [activePeriod, completedPeriod]);
  });

  Widget buildWidget({MemberModel profile = admin}) => ProviderScope(
        overrides: [
          periodsRepositoryProvider.overrideWithValue(mockPeriodsRepo),
          currentMemberProfileProvider.overrideWith((ref) async => profile),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Scaffold(body: ArisanScreen()),
        ),
      );

  testWidgets('shows loading then active period + all periods', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Arisan Keluarga'), findsOneWidget);
    expect(find.text('Periode Berjalan'), findsOneWidget);
    expect(find.text('ARISAN PERIODE #1'), findsOneWidget);
    expect(find.text('Di rumah Ahmad Rasijan'), findsOneWidget);
    expect(find.text('Jl. Melati No. 17'), findsOneWidget);
    expect(find.text('Rp100.000'), findsOneWidget);
    // Riwayat periode (scroll ke bawah karena lazy ListView)
    await tester.dragUntilVisible(
      find.text('#0'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.text('Riwayat Periode'), findsOneWidget);
    expect(find.text('#0'), findsOneWidget);
    expect(find.text('Menang: Ahmad Rasijan'), findsOneWidget);
  });

  testWidgets('shows admin actions for active period', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Agenda Acara'), findsOneWidget);
    expect(find.text('Mulai Kocok'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('Periode Baru'), findsOneWidget);
  });

  testWidgets('hides admin actions for non-admin member', (tester) async {
    await tester.pumpWidget(buildWidget(profile: member));
    await tester.pumpAndSettle();

    expect(find.text('Mulai Kocok'), findsNothing);
    expect(find.text('Agenda Acara'), findsNothing);
    expect(find.text('Periode Baru'), findsNothing);
    // Info periode tetap tampil
    expect(find.text('ARISAN PERIODE #1'), findsOneWidget);
  });

  testWidgets('shows empty state when no periods and admin can create',
      (tester) async {
    when(() => mockPeriodsRepo.getPeriods()).thenAnswer((_) async => []);
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada periode arisan'), findsOneWidget);
    expect(find.text('Buat Periode Baru'), findsOneWidget);
  });
}