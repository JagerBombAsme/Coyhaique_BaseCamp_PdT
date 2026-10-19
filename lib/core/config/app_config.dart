abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey =
      String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'Falta configurar SUPABASE_URL.',
      );
    }

    if (supabasePublishableKey.isEmpty) {
      throw StateError(
        'Falta configurar SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }
}