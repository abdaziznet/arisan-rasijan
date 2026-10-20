import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/tahlil_reading.dart';

abstract interface class TahlilanRepository {
  Future<List<TahlilReading>> loadAll();
}

class AssetTahlilanRepository implements TahlilanRepository {
  AssetTahlilanRepository({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const assetPath = 'assets/data/tahlilan.json';
  final AssetBundle _assetBundle;

  @override
  Future<List<TahlilReading>> loadAll() async {
    final jsonString = await _assetBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('Format bacaan tahlilan tidak valid.');
    }

    return (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => TahlilReading.fromJson(Map<String, dynamic>.from(item)))
        .where((reading) =>
            reading.id > 0 &&
            reading.title.isNotEmpty &&
            reading.arabic.isNotEmpty)
        .toList(growable: false);
  }
}
