import 'package:bani_rasijan/features/draw/presentation/providers/draw_providers.dart';
import 'package:bani_rasijan/features/draw/presentation/screens/draw_screen.dart';
import 'package:bani_rasijan/features/members/domain/member_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

void main() {
  Widget buildApp(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: DrawScreen(periodId: 'p1'),
      ),
    );
  }

  group('DrawScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(buildApp([
        // Leaving drawCandidatesForPeriodProvider to default which might trigger actual fetch
        // Let's mock it
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Completer<List<MemberModel>>().future),
      ]));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows button enabled when all conditions are met', (tester) async {
      await tester.pumpWidget(buildApp([
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Future.value([
          const MemberModel(id: 'm1', fullName: 'Member 1', phoneNumber: '', address: '', isActive: true)
        ])),
        drawHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
        allMembersPaidProvider.overrideWith((ref) => Future.value(true)),
        isDrawDayProvider.overrideWithValue(true),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(false)),
      ]));

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isTrue);
    });

    testWidgets('shows button disabled when not all members paid', (tester) async {
      await tester.pumpWidget(buildApp([
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Future.value([
          const MemberModel(id: 'm1', fullName: 'Member 1', phoneNumber: '', address: '', isActive: true)
        ])),
        drawHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
        allMembersPaidProvider.overrideWith((ref) => Future.value(false)),
        isDrawDayProvider.overrideWithValue(true),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(false)),
      ]));

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isFalse);
    });

    testWidgets('shows button disabled when not draw day', (tester) async {
      await tester.pumpWidget(buildApp([
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Future.value([
          const MemberModel(id: 'm1', fullName: 'Member 1', phoneNumber: '', address: '', isActive: true)
        ])),
        drawHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
        allMembersPaidProvider.overrideWith((ref) => Future.value(true)),
        isDrawDayProvider.overrideWithValue(false),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(false)),
      ]));

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isFalse);
    });

    testWidgets('shows button disabled when draw already done', (tester) async {
      await tester.pumpWidget(buildApp([
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Future.value([
          const MemberModel(id: 'm1', fullName: 'Member 1', phoneNumber: '', address: '', isActive: true)
        ])),
        drawHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
        allMembersPaidProvider.overrideWith((ref) => Future.value(true)),
        isDrawDayProvider.overrideWithValue(true),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(true)),
      ]));

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isFalse);
    });

    testWidgets('opens confirmation dialog on click when enabled', (tester) async {
      await tester.pumpWidget(buildApp([
        drawCandidatesForPeriodProvider('p1').overrideWith((ref) => Future.value([
          const MemberModel(id: 'm1', fullName: 'Member 1', phoneNumber: '', address: '', isActive: true)
        ])),
        drawHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
        allMembersPaidProvider.overrideWith((ref) => Future.value(true)),
        isDrawDayProvider.overrideWithValue(true),
        isDrawAlreadyDoneProvider.overrideWith((ref) => Future.value(false)),
      ]));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Mulai Kocokan'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Kocokan'), findsOneWidget);
      expect(find.text('Ya, Kocok Sekarang'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
