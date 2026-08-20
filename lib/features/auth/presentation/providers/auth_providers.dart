import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/domain/auth_state.dart';
import '../controllers/auth_controller.dart';
import 'auth_repository_provider.dart';

// Re-export supaya consumer cukup import satu file
export 'auth_repository_provider.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

final authControllerProvider =
    NotifierProvider<AuthController, AuthScreenState>(AuthController.new);

// ---------------------------------------------------------------------------
// Auth state changes stream (dari Supabase)
// ---------------------------------------------------------------------------

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).onAuthStateChange;
});

// ---------------------------------------------------------------------------
// Session saat ini
// ---------------------------------------------------------------------------

final currentSessionProvider = Provider<Session?>((ref) {
  return ref.read(authRepositoryProvider).currentSession;
});
