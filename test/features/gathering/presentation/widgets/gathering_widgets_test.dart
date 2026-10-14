import 'package:bani_rasijan/features/gathering/domain/fund_ledger_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_event_model.dart';
import 'package:bani_rasijan/features/gathering/domain/gathering_poll_option_model.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/gathering_event_card.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/gathering_fund_card.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/gathering_ledger_list.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/voting_option_card.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/voting_progress_bar.dart';
import 'package:bani_rasijan/features/gathering/presentation/widgets/voting_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GatheringEventCard', () {
    testWidgets('renders event details and status properly', (tester) async {
      final event = GatheringEventModel(
        id: 'event-1',
        title: 'Gathering Bandung 2026',
        status: 'decided',
        eventDate: DateTime(2026, 12, 25),
        fundUsed: 2500000,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 10, 1),
      );

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatheringEventCard(
              event: event,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Gathering Bandung 2026'), findsOneWidget);
      expect(find.text('TUJUAN TERPILIH'), findsOneWidget);
      expect(find.text('Alokasi Kas: Rp2.500.000'), findsOneWidget);

      await tester.tap(find.text('Gathering Bandung 2026'));
      expect(tapped, isTrue);
    });
  });

  group('GatheringFundCard', () {
    testWidgets('renders fund balance and sub-stats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GatheringFundCard(
              balance: 4500000,
              totalInflow: 5000000,
              totalOutflow: 500000,
            ),
          ),
        ),
      );

      expect(find.text('Total Saldo Kas Gathering'), findsOneWidget);
      expect(find.text('Rp4.500.000'), findsOneWidget);
      expect(find.text('Rp5.000.000'), findsOneWidget);
      expect(find.text('Rp500.000'), findsOneWidget);
    });
  });

  group('GatheringLedgerList', () {
    testWidgets('renders ledger entries properly with colors', (tester) async {
      final entries = [
        FundLedgerModel(
          id: 'l-1',
          type: 'contribution_allocation',
          amount: 100000,
          description: 'Alokasi Iuran #1',
          createdBy: 'user-1',
          createdAt: DateTime(2026, 10, 1),
        ),
        FundLedgerModel(
          id: 'l-2',
          type: 'gathering_expense',
          amount: -50000,
          description: 'Pengeluaran Acara #1',
          createdBy: 'user-1',
          createdAt: DateTime(2026, 10, 2),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatheringLedgerList(
              entries: entries,
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Alokasi Iuran #1'), findsOneWidget);
      expect(find.text('+ Rp100.000'), findsOneWidget);
      expect(find.text('Pengeluaran Acara #1'), findsOneWidget);
      expect(find.text('- Rp50.000'), findsOneWidget);
    });
  });

  group('VotingOptionCard', () {
    testWidgets('triggers onTap and highlights when selected', (tester) async {
      final option = GatheringPollOptionModel(
        id: 'opt-1',
        gatheringEventId: 'e-1',
        optionLabel: 'Wisata Pangandaran',
        createdAt: DateTime.now(),
      );

      bool selected = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: VotingOptionCard(
                  option: option,
                  isSelected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Wisata Pangandaran'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.text('Wisata Pangandaran'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('VotingProgressBar', () {
    testWidgets('renders ratio and percentage calculation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VotingProgressBar(
              votedCount: 12,
              totalMembers: 17,
            ),
          ),
        ),
      );

      expect(find.text('12 / 17 anggota (71%)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('VotingResultCard', () {
    testWidgets('renders winning badge when marked as winning', (tester) async {
      final option = GatheringPollOptionModel(
        id: 'opt-1',
        gatheringEventId: 'e-1',
        optionLabel: 'Villa Puncak Bogor',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VotingResultCard(
              option: option,
              voteCount: 15,
              totalVotes: 20,
              isWinning: true,
            ),
          ),
        ),
      );

      expect(find.text('Villa Puncak Bogor'), findsOneWidget);
      expect(find.text('TERPILIH'), findsOneWidget);
      expect(find.text('15 suara'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
    });
  });
}
