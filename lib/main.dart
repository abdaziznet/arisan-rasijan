import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initializeDateFormatting('id_ID');
  await SupabaseConfig.initialize();

  // Setup deep link handling for magic link callbacks
  final appLinks = AppLinks();

  // Handle initial link (app opened from terminated state)
  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  } catch (e) {
    // Ignore errors on initial link
  }

  // Handle subsequent links (app already running)
  appLinks.uriLinkStream.listen((Uri uri) {
    _handleDeepLink(uri);
  }, onError: (err) {
    // Ignore stream errors
  });

  runApp(const ProviderScope(child: BaniRasijanApp()));
}

void _handleDeepLink(Uri uri) {
  // Handle both old and new redirect URL schemes for backward compatibility
  final isLoginCallback = uri.host == 'login-callback' &&
      (uri.scheme == 'net.abdaziz.arisanbanirasijan' ||
       uri.scheme == 'com.example.banirasijan');

  if (isLoginCallback) {
    // Supabase Flutter SDK handles the session recovery automatically
    // when the app opens with the auth callback URL
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  }
}
