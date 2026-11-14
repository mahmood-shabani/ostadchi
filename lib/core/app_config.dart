class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.startsWith('sb_publishable_');

  static const appVersion = '0.5.0';
}
