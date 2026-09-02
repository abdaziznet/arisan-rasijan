import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/supabase_config.dart';

class AuthRepository {
  AuthRepository({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
    String? webClientId,
  })  : _client = client ?? SupabaseConfig.client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: webClientId ?? EnvConfig.googleWebClientId,
            );

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Sign-in menggunakan Google Native OAuth
  Future<AuthResponse> signInWithGoogle() async {
    try {
      log('--- [AUTH] Memulai Google Sign-In...');
      // Reset state Google lokal (disconnect + signOut) agar account chooser dialog selalu dipaksa tampil
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        log('--- [AUTH] Warning saat pre-signIn disconnect: $e');
      }
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        log('--- [AUTH] Warning saat pre-signIn signOut: $e');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log('--- [AUTH] Login Google dibatalkan oleh pengguna.');
        throw const AuthException('Login Google dibatalkan');
      }

      log('--- [AUTH] Akun Google terpilih: ${googleUser.email} (ID: ${googleUser.id})');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      log('--- [AUTH] ID Token exists: ${idToken != null}, AccessToken exists: ${accessToken != null}');
      if (idToken == null) {
        log('--- [AUTH ERROR] ID Token null dari Google SDK. Periksa Google Web Client ID.');
        throw const AuthException('ID Token Google tidak ditemukan');
      }

      log('--- [AUTH] Mengirim ID Token ke Supabase auth.signInWithIdToken...');
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      log('--- [AUTH SUCCESS] Berhasil login Supabase! User ID: ${res.user?.id}, Email: ${res.user?.email}');
      return res;
    } catch (e, st) {
      log('--- [AUTH ERROR DETAIL] Google Sign-In Exception: $e');
      log('--- [AUTH STACKTRACE] $st');
      rethrow;
    }
  }

  /// Kirim Magic Link ke [email] (fallback jika diperlukan).
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

  /// Redeem kode undangan & aktifkan profil anggota baru via Supabase RPC.
  Future<bool> redeemInviteCodeAndCreateProfile({
    required String code,
    required String fullName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final response = await _client.rpc(
        'redeem_invite_code',
        params: {
          'p_code': code.trim(),
          'p_full_name': fullName.trim(),
          'p_phone_number': phoneNumber?.trim(),
          'p_address': address?.trim(),
        },
      );

      if (response is Map && response['success'] == true) {
        return true;
      }
      return true;
    } catch (e) {
      log('redeemInviteCodeAndCreateProfile error: $e');
      rethrow;
    }
  }

  /// Logout dan hapus session dari Google & Supabase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      log('GoogleSignIn signOut error: $e');
    }
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      log('GoogleSignIn disconnect error: $e');
    }
    await _client.auth.signOut();
  }
}
