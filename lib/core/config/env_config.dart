import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_URL tidak ditemukan di .env');
    return v!;
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    assert(
      v != null && v.isNotEmpty,
      'SUPABASE_ANON_KEY tidak ditemukan di .env',
    );
    return v!;
  }

  static String? get googleWebClientId {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    return (v != null && v.isNotEmpty) ? v : null;
  }

  /// Redirect URL untuk Magic Link — harus didaftarkan di Supabase Dashboard
  /// → Authentication → URL Configuration → Redirect URLs
  static String get redirectUrl {
    // kIsWeb adalah konstanta compile-time
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'com.example.banirasijan://login-callback';
  }
}
