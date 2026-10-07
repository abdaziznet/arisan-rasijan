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
      log('--- [AUTH REPO] Starting Google Sign-In...');
      log('--- [AUTH REPO] Google Web Client ID: ${EnvConfig.googleWebClientId}');
      log('--- [AUTH REPO] Supabase URL: ${EnvConfig.supabaseUrl}');

      // Reset state Google lokal (disconnect + signOut) agar account chooser dialog selalu dipaksa tampil
      try {
        await _googleSignIn.disconnect();
        log('--- [AUTH REPO] Google disconnect OK');
      } catch (e) {
        log('--- [AUTH REPO] Warning saat pre-signIn disconnect: $e');
      }
      try {
        await _googleSignIn.signOut();
        log('--- [AUTH REPO] Google signOut OK');
      } catch (e) {
        log('--- [AUTH REPO] Warning saat pre-signIn signOut: $e');
      }

      log('--- [AUTH REPO] Calling _googleSignIn.signIn()...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log('--- [AUTH REPO] Login Google dibatalkan oleh pengguna (googleUser == null).');
        throw const AuthException('Login Google dibatalkan');
      }

      log('--- [AUTH REPO] Google user selected: ${googleUser.email} (ID: ${googleUser.id})');
      log('--- [AUTH REPO] Requesting Google authentication tokens...');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      log('--- [AUTH REPO] ID Token exists: ${idToken != null}');
      log('--- [AUTH REPO] Access Token exists: ${accessToken != null}');
      if (idToken == null) {
        log('--- [AUTH REPO ERROR] ID Token null dari Google SDK. Periksa Google Web Client ID di Google Cloud Console & .env');
        throw const AuthException('ID Token Google tidak ditemukan');
      }
      log('--- [AUTH REPO] ID Token (first 50 chars): ${idToken.substring(0, idToken.length > 50 ? 50 : idToken.length)}...');

      log('--- [AUTH REPO] Sending ID Token to Supabase auth.signInWithIdToken...');
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      log('--- [AUTH REPO SUCCESS] Supabase login successful! User ID: ${res.user?.id}, Email: ${res.user?.email}, Session: ${res.session != null}');
      return res;
    } catch (e, st) {
      log('--- [AUTH REPO ERROR DETAIL] Google Sign-In Exception: $e');
      log('--- [AUTH REPO STACKTRACE] $st');
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
