import 'dart:async';

import 'package:bani_rasijan/features/auth/data/auth_repository.dart';
import 'package:bani_rasijan/features/auth/presentation/providers/auth_providers.dart';
import 'package:bani_rasijan/features/home/presentation/home_screen.dart';
import 'package:bani_rasijan/features/gathering/data/gathering_repository.dart';
import 'package:bani_rasijan/features/gathering/domain/fund_ledger_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/members/data/members_repository.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository.dart';
import 'package:bani_rasijan/features/periods/data/periods_repository_provider.dart';
import 'package:bani_rasijan/features/periods/domain/period_model.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bani_rasijan/core/services/connectivity_service.dart';

class MockMembersRepository extends Mock implements MembersRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockPeriodsRepository extends Mock implements PeriodsRepository {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockGatheringRepository extends Mock implements GatheringRepository {}

void main() {
  late MockMembersRepository mockMembersRepo;
  late MockAuthRepository mockAuthRepo;
  late MockPeriodsRepository mockPeriodsRepo;
  late MockConnectivityService mockConnectivityService;
  late MockGatheringRepository mockGatheringRepo;

  const sampleAdmin = MemberModel(
    id: 'm-1',
    fullName: 'Ahmad Rasijan',
    role: 'admin',
  );

  final samplePeriod = PeriodModel(
    id: 'p-1',
    periodNumber: 1,
    eventDate: DateTime(2026, 10, 15),
    hostAddress: 'Jl. Melati No. 17',
    contributionAmount: 100000,
    status: 'upcoming',
    host: sampleAdmin,
  );

  setUp(() {
    mockMembersRepo = MockMembersRepository();
    mockAuthRepo = MockAuthRepository();
    mockPeriodsRepo = MockPeriodsRepository();
    mockConnectivityService = MockConnectivityService();
    mockGatheringRepo = MockGatheringRepository();

    final controller = StreamController<ConnectionStatus>();

    when(() => mockAuthRepo.currentSession).thenReturn(null);
    when(() => mockMembersRepo.getMembers())
        .thenAnswer((_) async => [sampleAdmin]);
    when(() => mockMembersRepo.getMemberById('m-1'))
        .thenAnswer((_) async => sampleAdmin);
    when(() => mockPeriodsRepo.getActivePeriod())
        .thenAnswer((_) async => samplePeriod);
    when(() => mockPeriodsRepo.getPeriods())
        .thenAnswer((_) async => [samplePeriod]);
    when(() => mockConnectivityService.checkInitialConnection())
        .thenAnswer((_) async => ConnectionStatus.online);
    when(() => mockConnectivityService.connectionStatusController).thenReturn(controller);
    when(() => mockGatheringRepo.getFundLedger()).thenAnswer(
      (_) async => [
        FundLedgerModel(
          id: 'ledger-income',
          type: 'contribution_allocation',
          amount: 150000,
          createdBy: 'm-1',
          createdAt: DateTime(2026, 10, 15),
        ),
        FundLedgerModel(
          id: 'ledger-expense',
          type: 'gathering_expense',
          amount: -25000,
          createdBy: 'm-1',
          createdAt: DateTime(2026, 10, 16),
        ),
      ],
    );

    // Start with an online status
    controller.add(ConnectionStatus.online);
  });

  Widget buildWidget() => ProviderScope(
        overrides: [
          membersRepositoryProvider.overrideWithValue(mockMembersRepo),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          periodsRepositoryProvider.overrideWithValue(mockPeriodsRepo),
          currentMemberProfileProvider.overrideWith((ref) async => sampleAdmin),
          connectivityServiceProvider.overrideWithValue(mockConnectivityService),
          connectionStatusProvider.overrideWith((ref) => Stream.value(ConnectionStatus.online)),
          gatheringRepositoryProvider.overrideWithValue(mockGatheringRepo),
        ],
        child: const MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: HomeScreen(),
        ),
      );

  testWidgets('renders home screen with active period data & admin actions',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Assalamu’alaikum,'), findsOneWidget);
    expect(find.text('Ahmad Rasijan'), findsAtLeast(1));
    expect(find.text('ARISAN PERIODE #1'), findsOneWidget);
    expect(find.text('Di rumah Ahmad Rasijan'), findsOneWidget);
    expect(find.text('Aksi Cepat Admin'), findsOneWidget);
    expect(find.text('Periode Baru'), findsOneWidget);
    expect(find.text('Rp125.000'), findsOneWidget);
  });

  testWidgets('shows offline banner when internet is disconnected', (tester) async {
    // Override the connection status provider to be offline
    Widget buildOfflineWidget() => ProviderScope(
      overrides: [
        membersRepositoryProvider.overrideWithValue(mockMembersRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        periodsRepositoryProvider.overrideWithValue(mockPeriodsRepo),
        currentMemberProfileProvider.overrideWith((ref) async => sampleAdmin),
        connectivityServiceProvider.overrideWithValue(mockConnectivityService),
        connectionStatusProvider.overrideWith((ref) => Stream.value(ConnectionStatus.offline)),
        gatheringRepositoryProvider.overrideWithValue(mockGatheringRepo),
      ],
      child: const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: HomeScreen(),
      ),
    );

    await tester.pumpWidget(buildOfflineWidget());
    await tester.pumpAndSettle();

    expect(find.text('Anda sedang offline. Data mungkin tidak terbaru.'), findsOneWidget);
  });
}
