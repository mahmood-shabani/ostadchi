import 'package:flutter_test/flutter_test.dart';
import 'package:ostadchi/core/config/app_config.dart';

void main() {
  test('Supabase configuration is present', () {
    expect(AppConfig.hasSupabaseConfig, isTrue);
    expect(AppConfig.supabaseUrl, startsWith('https://'));
    expect(AppConfig.supabaseAnonKey, isNotEmpty);
  });
}
