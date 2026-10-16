import 'package:bani_rasijan/features/quran/data/quran_repository.dart';
import 'package:bani_rasijan/features/quran/domain/quran_models.dart';
import 'package:bani_rasijan/features/quran/presentation/quran_providers.dart';
import 'package:bani_rasijan/features/quran/presentation/quran_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeQuranRepository implements QuranRepository {
  @override
  Future<List<QuranSurah>> getSurahs() async => const [
        QuranSurah(
          number: 36,
          nameArabic: 'يس',
          nameLatin: 'Yasin',
          meaning: 'Yasin',
          verseCount: 83,
          revelationPlace: 'Mekah',
        ),
        QuranSurah(
          number: 1,
          nameArabic: 'الفاتحة',
          nameLatin: 'Al-Fatihah',
          meaning: 'Pembukaan',
          verseCount: 7,
          revelationPlace: 'Mekah',
        ),
      ];

  @override
  Future<QuranSurahDetail> getSurah(int number) async => QuranSurahDetail(
        number: number,
        nameArabic: 'الفاتحة',
        nameLatin: 'Al-Fatihah',
        meaning: 'Pembukaan',
        verseCount: 1,
        revelationPlace: 'Mekah',
        verses: const [
          QuranVerse(
            number: 1,
            arabic: 'بِسْمِ اللَّهِ',
            transliteration: 'Bismillah',
            translation: 'Dengan nama Allah',
          ),
        ],
      );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows searchable surah list and source attribution',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        quranRepositoryProvider.overrideWithValue(_FakeQuranRepository())
      ],
      child: const MaterialApp(home: QuranScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Yasin'), findsOneWidget);
    expect(find.text('Sumber bacaan: Kementerian Agama RI'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pembukaan');
    await tester.pumpAndSettle();
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('Yasin'), findsNothing);
  });

  testWidgets('opens a surah with Arabic and Indonesian translation',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        quranRepositoryProvider.overrideWithValue(_FakeQuranRepository())
      ],
      child: const MaterialApp(home: QuranScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yasin'));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
    expect(find.text('Bismillah'), findsOneWidget);
    expect(find.text('Dengan nama Allah'), findsOneWidget);
    expect(find.byTooltip('Tandai ayat'), findsOneWidget);
  });
}
