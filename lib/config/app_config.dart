import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build flavor. dev = side-loadable debug build; prod = release identity.
enum Flavor { dev, prod }

/// Typed, immutable environment configuration.
///
/// Supabase values are empty until S20 wires the backend; the plumbing exists
/// now so later specs read config through [appConfigProvider], never globals.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  /// Reads compile-time values injected via `--dart-define-from-file`.
  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig(
    flavor: flavor,
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final Flavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isDev => flavor == Flavor.dev;
}

/// App-wide config. MUST be overridden in `bootstrap()`; throws otherwise so a
/// missing override fails loudly at startup rather than silently.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap()',
  ),
);
