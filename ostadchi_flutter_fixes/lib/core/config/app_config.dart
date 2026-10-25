class AppConfig {
  // Build-time values remain configurable; safe public defaults also prevent
  // a blank-configuration screen when a build runner drops dart-define values.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lvadrcplahdvfwrunkce.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_q14BdoqW6BBRrfGoGoyoUw_ig9AIHoc',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_ANON_KEY';
}
