import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/daily_prayer.dart';

abstract interface class DailyPrayerRepository {
  Future<List<DailyPrayer>> loadAll();
}

class AssetDailyPrayerRepository implements DailyPrayerRepository {
  AssetDailyPrayerRepository({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const assetPath = 'assets/data/doa_harian.json';
  final AssetBundle _assetBundle;

  @override
  Future<List<DailyPrayer>> loadAll() async {
    final jsonString = await _assetBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('Format data doa tidak valid.');
    }
    return (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => DailyPrayer.fromJson(Map<String, dynamic>.from(item)))
        .where((prayer) => prayer.id > 0 && prayer.title.isNotEmpty)
        .toList(growable: false);
  }
}
