class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.nameLatin,
    required this.meaning,
    required this.verseCount,
    required this.revelationPlace,
  });

  final int number;
  final String nameArabic;
  final String nameLatin;
  final String meaning;
  final int verseCount;
  final String revelationPlace;

  factory QuranSurah.fromJson(Map<String, dynamic> json) => QuranSurah(
        number: _asInt(json['nomor']),
        nameArabic: _asString(json['nama']),
        nameLatin: _asString(json['namaLatin']),
        meaning: _asString(json['arti']),
        verseCount: _asInt(json['jumlahAyat']),
        revelationPlace: _asString(json['tempatTurun']),
      );

  Map<String, dynamic> toJson() => {
        'nomor': number,
        'nama': nameArabic,
        'namaLatin': nameLatin,
        'arti': meaning,
        'jumlahAyat': verseCount,
        'tempatTurun': revelationPlace,
      };
}

class QuranVerse {
  const QuranVerse({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  final int number;
  final String arabic;
  final String transliteration;
  final String translation;

  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
        number: _asInt(json['nomorAyat']),
        arabic: _asString(json['teksArab']),
        transliteration: _asString(json['teksLatin']),
        translation: _asString(json['teksIndonesia']),
      );

  Map<String, dynamic> toJson() => {
        'nomorAyat': number,
        'teksArab': arabic,
        'teksLatin': transliteration,
        'teksIndonesia': translation,
      };
}

class QuranSurahDetail extends QuranSurah {
  const QuranSurahDetail({
    required super.number,
    required super.nameArabic,
    required super.nameLatin,
    required super.meaning,
    required super.verseCount,
    required super.revelationPlace,
    required this.verses,
  });

  final List<QuranVerse> verses;

  factory QuranSurahDetail.fromJson(Map<String, dynamic> json) {
    final base = QuranSurah.fromJson(json);
    final rawVerses = json['ayat'];
    return QuranSurahDetail(
      number: base.number,
      nameArabic: base.nameArabic,
      nameLatin: base.nameLatin,
      meaning: base.meaning,
      verseCount: base.verseCount,
      revelationPlace: base.revelationPlace,
      verses: rawVerses is List
          ? rawVerses
              .whereType<Map>()
              .map((item) => QuranVerse.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'ayat': verses.map((verse) => verse.toJson()).toList(),
      };
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String _asString(Object? value) => value is String ? value : '';
