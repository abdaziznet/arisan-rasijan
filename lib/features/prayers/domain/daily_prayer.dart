class DailyPrayer {
  const DailyPrayer({
    required this.id,
    required this.group,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.tags,
  });

  final int id;
  final String group;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String reference;
  final List<String> tags;

  factory DailyPrayer.fromJson(Map<String, dynamic> json) => DailyPrayer(
        id: _toInt(json['id']),
        group: _toString(json['grup']),
        title: _toString(json['nama']),
        arabic: _toString(json['ar']),
        transliteration: _toString(json['tr']),
        translation: _toString(json['idn']),
        reference: _toString(json['tentang']),
        tags: json['tag'] is List
            ? (json['tag'] as List).whereType<String>().toList(growable: false)
            : const [],
      );
}

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String _toString(Object? value) => value is String ? value : '';
