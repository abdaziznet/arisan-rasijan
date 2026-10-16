import 'package:flutter_test/flutter_test.dart';
import 'package:bani_rasijan/features/quran/domain/quran_models.dart';

void main() {
  group('Quran models', () {
    test('parses surah metadata and ignores unexpected nullable values', () {
      final surah = QuranSurah.fromJson({
        'nomor': 36,
        'nama': 'يس',
        'namaLatin': 'Yasin',
        'arti': 'Yasin',
        'jumlahAyat': 83,
        'tempatTurun': 'Mekah',
      });

      expect(surah.number, 36);
      expect(surah.nameLatin, 'Yasin');
      expect(surah.verseCount, 83);
      expect(QuranSurah.fromJson({}).number, 0);
    });

    test('round trips surah details with ayat text intact', () {
      final detail = QuranSurahDetail.fromJson({
        'nomor': 1,
        'nama': 'الفاتحة',
        'namaLatin': 'Al-Fatihah',
        'arti': 'Pembukaan',
        'jumlahAyat': 1,
        'tempatTurun': 'Mekah',
        'ayat': [
          {
            'nomorAyat': 1,
            'teksArab': 'بِسْمِ اللَّهِ',
            'teksLatin': 'Bismillah',
            'teksIndonesia': 'Dengan nama Allah',
          },
        ],
      });

      expect(detail.verses.single.arabic, 'بِسْمِ اللَّهِ');
      expect(detail.verses.single.translation, 'Dengan nama Allah');
      expect(QuranSurahDetail.fromJson(detail.toJson()).verses, hasLength(1));
    });
  });
}
