import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/supabase_config.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Kirim Magic Link ke [email].
  Future<void> signInWithOtp(String email) => _client.auth.signInWithOtp(
    email: email.trim(),
    emailRedirectTo: EnvConfig.redirectUrl,
  );

  /// Panggil Edge Function `redeem-invite-code`.
  /// Mengembalikan `true` jika berhasil, throw jika gagal.
  Future<void> redeemInviteCode({
    required String code,
    required String email,
  }) async {
    final response = await _client.functions.invoke(
      'redeem-invite-code',
      body: {'code': code.trim(), 'email': email.trim()},
    );

    // Edge Function mengembalikan status 200 + { success: true } jika valid.
    // Status lain atau success=false berarti kode tidak valid.
    if (response.status != 200) {
      throw const AuthException('Kode undangan tidak valid');
    }

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      throw const AuthException('Kode undangan tidak valid');
    }
  }

  /// Cek apakah profil sudah dibuat untuk user saat ini.
  Future<bool> hasProfile() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      return data != null;
    } catch (e) {
      log('hasProfile error: $e');
      return false;
    }
  }

  /// Logout dan hapus session.
  Future<void> signOut() => _client.auth.signOut();
}
