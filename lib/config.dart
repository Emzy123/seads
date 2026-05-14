class AppConfig {
  /// Override at build/run time, e.g. `--dart-define=BACKEND_URL=http://10.0.2.2:3000`
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://seads-backend.onrender.com',
  );
}
