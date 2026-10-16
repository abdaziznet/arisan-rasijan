import 'package:bani_rasijan/features/prayers/data/daily_prayer_repository.dart';
import 'package:bani_rasijan/features/prayers/domain/daily_prayer.dart';
import 'package:bani_rasijan/features/prayers/presentation/daily_prayer_providers.dart';
import 'package:bani_rasijan/features/prayers/presentation/daily_prayers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDailyPrayerRepository implements DailyPrayerRepository {
  @override
  Future<List<DailyPrayer>> loadAll() async => const [
        DailyPrayer(
          id: 211,
          group: 'Doa Terkait Majelis',
          title: 'Doa Pembuka Pertemuan',
          arabic: 'رَبَّنَا',
          transliteration: 'Robbanaa',
          translation: 'Wahai Tuhan kami.',
          reference: 'Rujukan doa pembuka.',
          tags: ['majelis'],
        ),
        DailyPrayer(
          id: 135,
          group: 'Doa Terkait Makan',
          title: 'Doa Sebelum Makan',
          arabic: 'بِسْمِ اللَّهِ',
          transliteration: 'Bismillaah.',
          translation: 'Dengan nama Allah.',
          reference: 'Rujukan doa makan.',
          tags: ['makan'],
        ),
        DailyPrayer(
          id: 999,
          group: 'Doa Umum',
          title: 'Doa Lainnya',
          arabic: 'اللَّهُمَّ',
          transliteration: 'Allaahumma.',
          translation: 'Ya Allah.',
          reference: '',
          tags: ['umum'],
        ),
      ];
}

void main() {
  testWidgets('starts with arisan selection and can open all doa',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyPrayerRepositoryProvider
            .overrideWithValue(_FakeDailyPrayerRepository()),
      ],
      child: const MaterialApp(home: DailyPrayersScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Doa Pembuka Pertemuan'), findsOneWidget);
    expect(find.text('Doa Sebelum Makan'), findsOneWidget);
    expect(find.text('Doa Lainnya'), findsNothing);

    await tester.tap(find.text('Semua doa'));
    await tester.pumpAndSettle();
    expect(find.text('Doa Lainnya'), findsOneWidget);
  });

  testWidgets('opens selected doa detail with Arabic, latin and meaning',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyPrayerRepositoryProvider
            .overrideWithValue(_FakeDailyPrayerRepository()),
      ],
      child: const MaterialApp(home: DailyPrayersScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doa Sebelum Makan'));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
    expect(find.text('Bismillaah.'), findsOneWidget);
    expect(find.text('Dengan nama Allah.'), findsOneWidget);
    expect(find.text('Rujukan doa makan.'), findsOneWidget);
  });

  testWidgets('opens an agenda-selected prayer directly', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyPrayerRepositoryProvider
            .overrideWithValue(_FakeDailyPrayerRepository()),
      ],
      child: const MaterialApp(home: DailyPrayersScreen(initialPrayerId: 135)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Doa Sebelum Makan'), findsOneWidget);
    expect(find.text('Dengan nama Allah.'), findsOneWidget);
  });
}
