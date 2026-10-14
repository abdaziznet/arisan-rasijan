import 'package:bani_rasijan/features/history/domain/period_history_model.dart';
import 'package:bani_rasijan/features/history/presentation/widgets/history_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryTimelineItem', () {
    final sampleItem = PeriodHistoryModel(
      periodId: 'per-9',
      periodNumber: 9,
      hostId: 'host-1',
      hostName: 'Budi Rasijan',
      winnerId: 'win-1',
      winnerName: 'Ahmad Rasijan',
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 15),
      totalCollected: 8500000,
    );

    testWidgets('renders timeline item with winner, host, date, and collected amount',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryTimelineItem(
              item: sampleItem,
              isFirst: true,
              isLast: false,
              highlighted: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Node & Period title
      expect(find.text('#9'), findsOneWidget);
      expect(find.text('Periode #9'), findsOneWidget);

      // Winner info
      expect(find.text('Pemenang'), findsOneWidget);
      expect(find.text('Ahmad Rasijan'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      // Host info
      expect(find.text('Tuan Rumah'), findsOneWidget);
      expect(find.text('Budi Rasijan'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

      // Amount
      expect(find.text('Rp8.500.000'), findsOneWidget);
      expect(find.text('Total Terkumpul'), findsOneWidget);

      // Tap triggers callback
      await tester.tap(find.text('Periode #9'));
      expect(tapped, isTrue);
    });

    testWidgets('renders highlighted state with Dipilih badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryTimelineItem(
              item: sampleItem,
              isFirst: false,
              isLast: true,
              highlighted: true,
            ),
          ),
        ),
      );

      expect(find.text('Dipilih'), findsOneWidget);
    });
  });
}
