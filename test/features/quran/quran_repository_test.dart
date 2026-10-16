import 'package:bani_rasijan/features/quran/data/quran_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rejects an invalid surah number before making a request', () async {
    final repository = QuranRepositoryImpl();
    await expectLater(
        repository.getSurah(115), throwsA(isA<QuranDataException>()));
    await expectLater(
        repository.getSurah(0), throwsA(isA<QuranDataException>()));
  });

  test('loads previously cached surahs without network access', () async {
    SharedPreferences.setMockInitialValues({
      'quran.cache.v1.surahs':
          '[{"nomor":36,"nama":"يس","namaLatin":"Yasin","arti":"Yasin","jumlahAyat":83,"tempatTurun":"Mekah"}]',
    });
    final repository = QuranRepositoryImpl();

    final surahs = await repository.getSurahs();

    expect(surahs.single.number, 36);
    expect(surahs.single.nameLatin, 'Yasin');
  });
}
