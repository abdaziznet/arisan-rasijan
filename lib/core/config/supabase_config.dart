import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config.dart';

abstract final class SupabaseConfig {
  static Future<void> initialize() => Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        publishableKey: EnvConfig.supabaseAnonKey,
        debug: false,
      );

  static SupabaseClient get client => Supabase.instance.client;
}
