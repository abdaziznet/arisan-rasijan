class TahlilReading {
  const TahlilReading({
    required this.id,
    required this.title,
    required this.arabic,
    this.latin = '',
    required this.translation,
    this.repeat = 1,
    this.prefix,
  });

  final int id;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final int repeat;
  final TahlilPrefix? prefix;

  factory TahlilReading.fromJson(Map<String, dynamic> json) => TahlilReading(
        id: _toInt(json['id']),
        title: _toString(json['title']),
        arabic: _toString(json['arabic']),
        latin: _toString(json['latin']),
        translation: _toString(json['translation']),
        repeat: _toInt(json['repeat']).clamp(1, 10000).toInt(),
        prefix: json['prefix'] is Map
            ? TahlilPrefix.fromJson(
                Map<String, dynamic>.from(json['prefix'] as Map),
              )
            : null,
      );
}

class TahlilPrefix {
  const TahlilPrefix({
    required this.arabic,
    this.latin = '',
    this.translation = '',
  });

  final String arabic;
  final String latin;
  final String translation;

  factory TahlilPrefix.fromJson(Map<String, dynamic> json) => TahlilPrefix(
        arabic: _toString(json['arabic']),
        latin: _toString(json['latin']),
        translation: _toString(json['translation']),
      );
}

int _toInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String _toString(Object? value) => value is String ? value : '';
