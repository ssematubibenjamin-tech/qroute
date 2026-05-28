// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/core/supabase_config.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://qwkumohlstnpckukfale.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_7gOBduhsmjjoiwpnpQ5wag_EHFiiLNX';

  static SupabaseClient get client => Supabase.instance.client;
}

// Convenience global accessor used across all screens
final supabase = SupabaseConfig.client;
