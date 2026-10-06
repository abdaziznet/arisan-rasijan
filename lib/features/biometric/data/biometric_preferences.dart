import 'package:shared_preferences/shared_preferences.dart';

class BiometricPreferences {
  static const String _keyEnabled = 'bio_auth_enabled';
  static const String _keyTimeout = 'bio_auto_lock_timeout';
  static const String _keyLastBackground = 'bio_last_background_time';
  static const String _keyFailedAttempts = 'bio_failed_attempts';
  static const String _keyPromptOffered = 'bio_prompt_offered';

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<bool> isBiometricEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<int> getAutoLockTimeoutMinutes() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyTimeout) ?? 1;
  }

  Future<void> setAutoLockTimeoutMinutes(int minutes) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyTimeout, minutes);
  }

  Future<int> getLastBackgroundTime() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyLastBackground) ?? 0;
  }

  Future<void> setLastBackgroundTime(int timestamp) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyLastBackground, timestamp);
  }

  Future<void> clearLastBackgroundTime() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyLastBackground);
  }

  Future<int> getFailedAttempts() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyFailedAttempts) ?? 0;
  }

  Future<int> incrementFailedAttempts() async {
    final prefs = await _getPrefs();
    final current = prefs.getInt(_keyFailedAttempts) ?? 0;
    final updated = current + 1;
    await prefs.setInt(_keyFailedAttempts, updated);
    return updated;
  }

  Future<void> resetFailedAttempts() async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyFailedAttempts, 0);
  }

  Future<bool> isPromptOffered() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyPromptOffered) ?? false;
  }

  Future<void> setPromptOffered(bool offered) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyPromptOffered, offered);
  }

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyTimeout);
    await prefs.remove(_keyLastBackground);
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyPromptOffered);
  }
}
