import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quran_models.dart';

abstract interface class QuranRepository {
  Future<List<QuranSurah>> getSurahs();
  Future<QuranSurahDetail> getSurah(int number);
}

class QuranDataException implements Exception {
  const QuranDataException(this.message);
  final String message;
  @override
  String toString() => message;
}

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({HttpClient? client}) : _client = client ?? HttpClient();

  static const _baseUrl = 'https://equran.id/api/v2';
  static const _surahCacheKey = 'quran.cache.v1.surahs';
  static const _surahDetailPrefix = 'quran.cache.v1.surah.';
  final HttpClient _client;

  @override
  Future<List<QuranSurah>> getSurahs() async {
    final cached = await _readCache(_surahCacheKey);
    if (cached != null) {
      return _parseSurahList(cached);
    }
    final response = await _get('/surat');
    final data = _unwrap(response);
    if (data is! List)
      throw const QuranDataException('Data daftar surah tidak valid.');
    final surahs = data
        .whereType<Map>()
        .map((row) => QuranSurah.fromJson(Map<String, dynamic>.from(row)))
        .where((surah) => surah.number >= 1 && surah.number <= 114)
        .toList(growable: false);
    if (surahs.isEmpty) throw const QuranDataException('Daftar surah kosong.');
    await _writeCache(_surahCacheKey, data);
    return surahs;
  }

  @override
  Future<QuranSurahDetail> getSurah(int number) async {
    if (number < 1 || number > 114) {
      throw const QuranDataException('Nomor surah harus antara 1 dan 114.');
    }
    final key = '$_surahDetailPrefix$number';
    final cached = await _readCache(key);
    if (cached != null) return QuranSurahDetail.fromJson(cached);

    final response = await _get('/surat/$number');
    final data = _unwrap(response);
    if (data is! Map) throw const QuranDataException('Data surah tidak valid.');
    final detail = QuranSurahDetail.fromJson(Map<String, dynamic>.from(data));
    if (detail.number != number || detail.verses.isEmpty) {
      throw const QuranDataException('Isi surah tidak lengkap.');
    }
    await _writeCache(key, detail.toJson());
    return detail;
  }

  Future<dynamic> _get(String path) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final request = await _client
            .getUrl(Uri.parse('$_baseUrl$path'))
            .timeout(const Duration(seconds: 15));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response =
            await request.close().timeout(const Duration(seconds: 15));
        if (response.statusCode >= 500 && attempt < 2) {
          await response.drain<void>();
          await Future<void>.delayed(
              Duration(milliseconds: 250 * (attempt + 1)));
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw QuranDataException(
              'Layanan bacaan tidak tersedia (${response.statusCode}).');
        }
        final body = await utf8.decoder.bind(response).join();
        try {
          return jsonDecode(body);
        } on FormatException {
          throw const QuranDataException('Respons bacaan tidak dapat dibaca.');
        }
      } on SocketException {
        if (attempt == 2) {
          throw const QuranDataException(
              'Periksa koneksi internet lalu coba lagi.');
        }
      } on TimeoutException {
        if (attempt == 2) {
          throw const QuranDataException(
              'Waktu memuat bacaan habis. Coba lagi.');
        }
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    throw const QuranDataException('Gagal memuat bacaan. Coba lagi.');
  }

  dynamic _unwrap(dynamic response) {
    if (response is Map && response.containsKey('data')) {
      final code = response['code'];
      if (code is num && code >= 400) {
        throw QuranDataException(
            _stringOr(response['message'], 'Gagal memuat bacaan.'));
      }
      return response['data'];
    }
    return response;
  }

  Future<dynamic> _readCache(String key) async {
    final value = (await SharedPreferences.getInstance()).getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      await (await SharedPreferences.getInstance()).remove(key);
      return null;
    }
  }

  Future<void> _writeCache(String key, dynamic value) async {
    await (await SharedPreferences.getInstance())
        .setString(key, jsonEncode(value));
  }

  List<QuranSurah> _parseSurahList(dynamic data) {
    if (data is! List)
      throw const QuranDataException('Cache daftar surah tidak valid.');
    return data
        .whereType<Map>()
        .map((row) => QuranSurah.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  String _stringOr(Object? value, String fallback) =>
      value is String && value.isNotEmpty ? value : fallback;
}

Future<void> saveLastRead(int surahNumber, int verseNumber) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('quran.last.surah', surahNumber);
  await prefs.setInt('quran.last.verse', verseNumber);
}

Future<(int, int)?> loadLastRead() async {
  final prefs = await SharedPreferences.getInstance();
  final surah = prefs.getInt('quran.last.surah');
  final verse = prefs.getInt('quran.last.verse');
  return surah == null ? null : (surah, verse ?? 1);
}

Future<Set<String>> loadQuranBookmarks() async {
  final values = (await SharedPreferences.getInstance())
          .getStringList('quran.bookmarks') ??
      [];
  return values.toSet();
}

Future<void> setQuranBookmark(
    int surahNumber, int verseNumber, bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  final values = (prefs.getStringList('quran.bookmarks') ?? []).toSet();
  final key = '$surahNumber:$verseNumber';
  if (enabled) {
    values.add(key);
  } else {
    values.remove(key);
  }
  await prefs.setStringList('quran.bookmarks', values.toList()..sort());
}

String quranBookmarkKey(int surahNumber, int verseNumber) =>
    '$surahNumber:$verseNumber';
