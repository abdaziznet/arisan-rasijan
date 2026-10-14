import 'package:bani_rasijan/features/history/domain/period_history_model.dart';
import 'package:bani_rasijan/features/history/presentation/providers/history_providers.dart';
import 'package:bani_rasijan/features/history/presentation/screens/history_screen.dart';
import 'package:bani_rasijan/features/history/presentation/widgets/history_summary_card.dart';
import 'package:bani_rasijan/features/history/presentation/widgets/history_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks.dart';

void main() {
  final sampleHistory = [
    PeriodHistoryModel(
      periodId: 'per-9',
      periodNumber: 9,
      hostId: 'host-1',
      hostName: 'Budi Rasijan',
      winnerId: 'win-1',
      winnerName: 'Ahmad Rasijan',
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 15),
      totalCollected: 8500000,
    ),
    PeriodHistoryModel(
      periodId: 'per-8',
      periodNumber: 8,
      hostId: 'host-2',
      hostName: 'Siti Rasijan',
      winnerId: 'win-2',
      winnerName: 'Budi Rasijan',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 15),
      totalCollected: 8500000,
    ),
  ];

  testWidgets('renders empty state when history list is empty', (tester) async {
    final mockRepo = MockHistoryRepository();
    when(() => mockRepo.getHistory()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Riwayat Arisan'), findsOneWidget);
    expect(
      find.textContaining('Riwayat akan otomatis tercatat setelah periode arisan selesai'),
      findsOneWidget,
    );
  });

  testWidgets('renders error state and retry button on failure', (tester) async {
    final mockRepo = MockHistoryRepository();
    when(() => mockRepo.getHistory()).thenThrow(Exception('Koneksi terputus'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gagal Memuat Riwayat'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('renders history list, summary card, and timeline items',
      (tester) async {
    final mockRepo = MockHistoryRepository();
    when(() => mockRepo.getHistory()).thenAnswer((_) async => sampleHistory);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Summary Card
    expect(find.byType(HistorySummaryCard), findsOneWidget);
    expect(find.text('Kilas Balik Arisan'), findsOneWidget);

    // Section Header
    expect(find.text('Timeline Riwayat'), findsOneWidget);
    expect(find.text('2 Periode'), findsOneWidget);

    // Timeline Items
    expect(find.byType(HistoryTimelineItem), findsNWidgets(2));
    expect(find.text('Periode #9'), findsOneWidget);
    expect(find.text('Periode #8'), findsOneWidget);
    expect(find.text('Ahmad Rasijan'), findsOneWidget);
    expect(find.text('Siti Rasijan'), findsOneWidget);
  });

  testWidgets('filters history items via search field', (tester) async {
    final mockRepo = MockHistoryRepository();
    when(() => mockRepo.getHistory()).thenAnswer((_) async => sampleHistory);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HistoryTimelineItem), findsNWidgets(2));

    // Type "Ahmad" into search field
    await tester.enterText(find.byType(TextField), 'Ahmad');
    await tester.pumpAndSettle();

    // Only Periode #9 should be visible (Ahmad was the winner)
    expect(find.byType(HistoryTimelineItem), findsOneWidget);
    expect(find.text('Periode #9'), findsOneWidget);
    expect(find.text('Periode #8'), findsNothing);

    // Type non-existent query
    await tester.enterText(find.byType(TextField), 'NonExistentPerson');
    await tester.pumpAndSettle();

    expect(find.byType(HistoryTimelineItem), findsNothing);
    expect(find.text('Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Reset Pencarian'), findsOneWidget);

    // Tap reset
    await tester.tap(find.text('Reset Pencarian'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryTimelineItem), findsNWidgets(2));
  });

  testWidgets('tapping timeline item opens detail bottom sheet', (tester) async {
    final mockRepo = MockHistoryRepository();
    when(() => mockRepo.getHistory()).thenAnswer((_) async => sampleHistory);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Periode #9
    await tester.tap(find.text('Periode #9'));
    await tester.pumpAndSettle();

    // Bottom sheet appears
    expect(find.text('Riwayat Pelaksanaan Arisan'), findsOneWidget);
    expect(find.text('Pemenang Undian (Kocokan)'), findsOneWidget);
    expect(find.text('Tuan Rumah Acara'), findsOneWidget);
    expect(find.text('Total Dana Tersalurkan'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // Tap Tutup to close
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Pelaksanaan Arisan'), findsNothing);
  });
}
