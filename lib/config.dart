/// Compile-time configuration for SEADS builds.
///
/// Examples:
/// ```bash
/// flutter run
/// flutter run --dart-define=DEMO_MODE=true
/// flutter run --dart-define=BACKEND_URL=http://10.0.2.2:3000
/// ```
class AppConfig {
  /// API base URL.
  /// Local machine (Linux/Desktop/Web): `http://localhost:3000` (default)
  /// Local Android emulator:            `--dart-define=BACKEND_URL=http://10.0.2.2:3000`
  /// Local physical device:             `--dart-define=BACKEND_URL=http://<your-lan-ip>:3000`
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
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

  /// Central emergency call line number across dashboards.
  static const String emergencyCallLine = '09164880144';

  /// Realtime poll bounds (informational; see [RealtimeSyncService]).
  static const int realtimePollMinSeconds = 2;
  static const int realtimePollMaxSeconds = 30;
}
