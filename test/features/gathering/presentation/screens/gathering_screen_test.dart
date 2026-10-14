import 'package:bani_rasijan/core/theme/app_colors.dart';
import 'package:bani_rasijan/core/widgets/app_components.dart';
import 'package:bani_rasijan/features/gathering/domain/fund_ledger_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/providers/gathering_providers.dart';
import 'package:bani_rasijan/features/gathering/presentation/screens/gathering_screen.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/gathering_fund_card.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:bani_rasijan/features/members/presentation/providers/members_providers.dart';
import 'package:bani_rasijan/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

void main() {
  late MockGatheringRepository mockGatheringRepository;
  late GatheringEventModel testEvent;
  late List<FundLedgerModel> testLedger;

  setUp(() {
    mockGatheringRepository = MockGatheringRepository();
    testEvent = GatheringEventModel(
      id: 'event-1',
      title: 'Test Gathering Event',
      status: 'voting',
      createdBy: 'admin-id',
      createdAt: DateTime.now(),
    );
    testLedger = [
      FundLedgerModel(
        id: 'ledger-1',
        type: 'contribution_allocation',
        amount: 50000,
        description: 'Alokasi Iuran Anggota',
        createdBy: 'admin-id',
        createdAt: DateTime.now(),
      ),
    ];

    when(() => mockGatheringRepository.getEvents())
        .thenAnswer((_) async => [testEvent]);
    when(() => mockGatheringRepository.getEvent('event-1'))
        .thenAnswer((_) async => testEvent);
    when(() => mockGatheringRepository.getPollOptions('event-1'))
        .thenAnswer((_) async => []);
    when(() => mockGatheringRepository.getFundLedger())
        .thenAnswer((_) async => testLedger);
    when(() => mockGatheringRepository.getGatheringTally(any()))
        .thenAnswer((_) async => {});
    when(() => mockGatheringRepository.hasMemberVoted(
          eventId: any(named: 'eventId'),
          memberId: any(named: 'memberId'),
        )).thenAnswer((_) async => false);
  });

  Widget createTestableWidget({bool isAdmin = true}) {
    return ProviderScope(
      overrides: [
        gatheringRepositoryProvider.overrideWithValue(mockGatheringRepository),
        currentMemberProfileProvider.overrideWith(
          (ref) async => MemberModel(
            id: 'admin-id',
            fullName: 'Admin',
            role: isAdmin ? 'admin' : 'member',
          ),
        ),
      ],
      child: const MaterialApp(
        home: GatheringScreen(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }

  testWidgets('renders list of gathering events with modern status badge',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test Gathering Event'), findsOneWidget);
    expect(find.text('VOTING DIBUKA'), findsOneWidget);
    expect(find.byType(AppBadge), findsOneWidget);
    expect(
      (tester.widget<AppBadge>(find.byType(AppBadge))).color,
      AppColors.primary,
    );

    await tester.tap(find.text('Test Gathering Event'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Acara Gathering'), findsOneWidget);
  });

  testWidgets('renders Kas Bersama tab with fund card and ledger list',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Switch to Kas Bersama tab
    await tester.tap(find.text('Kas Bersama'));
    await tester.pumpAndSettle();

    expect(find.byType(GatheringFundCard), findsOneWidget);
    expect(find.text('Total Saldo Kas Gathering'), findsOneWidget);
    expect(find.text('Riwayat Transaksi Kas'), findsOneWidget);
    expect(find.text('Alokasi Iuran Anggota'), findsOneWidget);
    expect(find.text('+ Rp50.000'), findsOneWidget);
  });
}
