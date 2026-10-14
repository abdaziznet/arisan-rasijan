import 'package:bani_rasijan/features/history/domain/period_history_model.dart';
import 'package:bani_rasijan/features/history/presentation/widgets/history_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistorySummaryCard', () {
    final sampleHistory = [
      PeriodHistoryModel(
        periodId: 'per-2',
        periodNumber: 2,
        hostId: 'host-2',
        hostName: 'Siti Rasijan',
        winnerId: 'win-2',
        winnerName: 'Ahmad Rasijan',
        startDate: DateTime(2026, 10, 15),
        endDate: DateTime(2026, 10, 15),
        totalCollected: 8500000,
      ),
      PeriodHistoryModel(
        periodId: 'per-1',
        periodNumber: 1,
        hostId: 'host-1',
        hostName: 'Budi Rasijan',
        winnerId: 'win-1',
        winnerName: 'Budi Rasijan',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 15),
        totalCollected: 8500000,
      ),
    ];

    testWidgets('renders title, stats, and badges correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorySummaryCard(history: sampleHistory),
          ),
        ),
      );

      // Header tags and title
      expect(find.text('ARSIP KELUARGA'), findsOneWidget);
      expect(find.text('Transparan'), findsOneWidget);
      expect(find.text('Kilas Balik Arisan'), findsOneWidget);
      expect(
        find.text('Jejak kebersamaan & amanah keluarga Bani Rasijan'),
        findsOneWidget,
      );

      // Statistics values
      expect(find.text('2'), findsOneWidget); // 2 Periode
      expect(find.text('Periode'), findsOneWidget);

      expect(find.text('Rp17.000.000'), findsOneWidget); // 8.5M + 8.5M
      expect(find.text('Dana Tersalurkan'), findsOneWidget);

      expect(find.text('Pemenang'), findsOneWidget);
    });

    testWidgets('handles empty history list gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistorySummaryCard(history: []),
          ),
        ),
      );

      expect(find.text('0'), findsNWidgets(2)); // 0 periode, 0 pemenang
      expect(find.text('Rp0'), findsOneWidget);
    });
  });
}
