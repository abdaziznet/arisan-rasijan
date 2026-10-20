import 'package:bani_rasijan/features/prayers/presentation/tahlilan_screen.dart';
import 'package:bani_rasijan/features/prayers/data/tahlilan_repository.dart';
import 'package:bani_rasijan/features/prayers/domain/tahlil_reading.dart';
import 'package:bani_rasijan/features/prayers/presentation/tahlilan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTahlilanRepository implements TahlilanRepository {
  @override
  Future<List<TahlilReading>> loadAll() async => const [
        TahlilReading(
          id: 1,
          title: 'Al-Fatihah',
          arabic: 'بِسْمِ اللهِ',
          latin: 'Bismillahirrahmanirrahim.',
          translation: 'Dengan nama Allah.',
          repeat: 3,
          prefix: TahlilPrefix(
            arabic: 'اَعُوْذُ بِاللهِ',
            latin: 'A\'udzu billahi.',
            translation: 'Aku berlindung kepada Allah.',
          ),
        ),
      ];
}

void main() {
  testWidgets('shows ordered Arabic and meanings with adjustable text',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tahlilanRepositoryProvider.overrideWithValue(_FakeTahlilanRepository()),
      ],
      child: const MaterialApp(home: TahlilanScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bacaan Tahlilan'), findsOneWidget);
    expect(find.text('1 bacaan • Arab dan artinya'), findsOneWidget);
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('Dibaca 3 kali'), findsOneWidget);
    expect(find.text('BACAAN PEMBUKA'), findsOneWidget);
    expect(find.text('A\'udzu billahi.'), findsOneWidget);
    expect(find.text('Bismillahirrahmanirrahim.'), findsOneWidget);
    expect(find.text('Dengan nama Allah.'), findsOneWidget);
    expect(find.text('ARTI'), findsNWidgets(2));

    final arabicFinder = find.text('بِسْمِ اللهِ');
    expect(tester.widget<Text>(arabicFinder).textDirection, TextDirection.rtl);
    expect(tester.widget<Text>(arabicFinder).style?.fontSize, 30);

    await tester.tap(find.text('A+'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(arabicFinder).style?.fontSize, 36);
  });
}
