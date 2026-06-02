import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('const ctor defaults supabase fields to empty', () {
    const c = AppConfig(flavor: Flavor.dev);
    check(c.flavor).equals(Flavor.dev);
    check(c.supabaseUrl).equals('');
    check(c.supabaseAnonKey).equals('');
    check(c.isDev).isTrue();
  });

  test('explicit values are retained', () {
    const c = AppConfig(
      flavor: Flavor.prod,
      supabaseUrl: 'https://x.supabase.co',
      supabaseAnonKey: 'anon',
    );
    check(c.flavor).equals(Flavor.prod);
    check(c.supabaseUrl).equals('https://x.supabase.co');
    check(c.isDev).isFalse();
  });

  test(
    'fromEnvironment uses the given flavor and defaults missing keys to empty',
    () {
      // No --dart-define provided in the test runner → keys default to ''.
      final c = AppConfig.fromEnvironment(Flavor.prod);
      check(c.flavor).equals(Flavor.prod);
      check(c.supabaseUrl).equals('');
      check(c.supabaseAnonKey).equals('');
    },
  );
}
