import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/validators.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../providers/auth_repository_provider.dart';

class AuthController extends Notifier<AuthScreenState> {
  @override
  AuthScreenState build() => const AuthInitial();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // ---------------------------------------------------------------------------
  // Magic Link (pengguna lama)
  // ---------------------------------------------------------------------------

  Future<void> sendMagicLink(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      state = AuthError(emailError);
      return;
    }

    state = const AuthLoading();
    try {
      await _repo.signInWithOtp(email);
      state = AuthMagicLinkSent(email.trim());
    } on AuthException catch (e) {
      state = AuthError(_friendlyAuthError(e));
    } catch (e) {
      log('sendMagicLink error: $e');
      state = const AuthError('Gagal mengirim link. Coba lagi.');
    }
  }

  // ---------------------------------------------------------------------------
  // Redeem invite code (pengguna baru)
  // ---------------------------------------------------------------------------

  Future<void> redeemInviteAndSendLink({
    required String code,
    required String email,
  }) async {
    final codeError = Validators.validateInviteCode(code);
    if (codeError != null) {
      state = AuthError(codeError);
      return;
    }
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      state = AuthError(emailError);
      return;
    }

    state = const AuthLoading();
    try {
      await _repo.redeemInviteCode(code: code, email: email);
      state = AuthMagicLinkSent(email.trim());
    } on AuthException {
      // Selalu pesan generik — jangan bocorkan detail (kadaluarsa, dicabut, dll)
      state = const AuthError('Kode undangan tidak valid');
    } catch (e) {
      log('redeemInviteCode error: $e');
      state = const AuthError('Kode undangan tidak valid');
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repo.signOut();
      state = const AuthInitial();
    } catch (e) {
      log('signOut error: $e');
      state = const AuthInitial(); // tetap logout dari perspektif UI
    }
  }

  // ---------------------------------------------------------------------------
  // Reset state
  // ---------------------------------------------------------------------------

  void reset() => state = const AuthInitial();

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  String _friendlyAuthError(AuthException e) {
    // Tidak bocorkan pesan mentah — petakan ke bahasa ramah pengguna
    final msg = e.message.toLowerCase();
    if (msg.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
    }
    if (msg.contains('token has expired')) {
      return 'Link atau kode OTP sudah kedaluwarsa. Minta yang baru.';
    }
    return 'Gagal mengirim link. Periksa koneksi lalu coba lagi.';
  }
}
