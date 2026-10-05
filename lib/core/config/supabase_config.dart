import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Default placeholder constants (can be overridden via environment or local preferences)
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  static bool isConfigured = false;

  static Future<void> initialize({String? customUrl, String? customKey}) async {
    final url = customUrl ?? defaultUrl;
    final key = customKey ?? defaultAnonKey;

    if (url.isNotEmpty &&
        !url.contains('placeholder') &&
        key.isNotEmpty &&
        !key.contains('placeholder')) {
      try {
        await Supabase.initialize(
          url: url,
          // ignore: deprecated_member_use
          anonKey: key,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        isConfigured = true;
      } catch (e) {
        isConfigured = false;
      }
    } else {
      isConfigured = false;
    }
  }

  static SupabaseClient? get client {
    if (isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
