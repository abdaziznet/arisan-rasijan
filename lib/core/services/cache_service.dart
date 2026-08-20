import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final cacheData = {
      'timestamp': now,
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }

  Future<Map<String, dynamic>?> getData(String key, {Duration maxAge = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      return null;
    }
    final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = DateTime.parse(cacheData['timestamp'] as String);

    if (DateTime.now().difference(timestamp) > maxAge) {
      await prefs.remove(key);
      return null;
    }

    return cacheData['data'] as Map<String, dynamic>;
  }
}
