/// Compile-time configuration for SEADS builds.
///
/// Examples:
/// ```bash
/// flutter run --dart-define=DEMO_MODE=true
/// flutter run --dart-define=BACKEND_URL=http://127.0.0.1:3000 --dart-define=ENV=staging
/// ```
class AppConfig {
  /// API base URL.
  /// Local Android emulator: `--dart-define=BACKEND_URL=http://10.0.2.2:3000`
  /// Local physical device:  `--dart-define=BACKEND_URL=http://<your-lan-ip>:3000`
  /// Production (Render):    `--dart-define=BACKEND_URL=https://<your-service>.onrender.com`
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// `dev` | `staging` | `prod` — informational / future feature flags.
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  /// When true, screens may show demo/mock data if APIs fail or return empty.
  /// Production builds should omit this define (defaults to false).
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static bool get isDemoMode => demoMode;

  static bool get isProduction => env == 'prod' && !demoMode;

  /// Use for UI fallbacks: never show fabricated data in production builds.
  static bool get allowDemoFallbacks => isDemoMode;

  /// Realtime poll bounds (informational; see [RealtimeSyncService]).
  static const int realtimePollMinSeconds = 2;
  static const int realtimePollMaxSeconds = 30;
}
