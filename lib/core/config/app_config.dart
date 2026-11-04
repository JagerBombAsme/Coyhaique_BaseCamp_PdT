abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError('Falta configurar SUPABASE_URL.');
    }

    if (supabasePublishableKey.isEmpty) {
      throw StateError('Falta configurar SUPABASE_PUBLISHABLE_KEY.');
    }
    
    if (mapboxAccessToken.isEmpty) {
      throw StateError('Falta configurar MAPBOX_ACCESS_TOKEN.');
    }
  }
}
