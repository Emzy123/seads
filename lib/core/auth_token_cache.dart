/// Caches the Firebase ID token for background isolates (no Firebase SDK there).
class AuthTokenCache {
  static String? _token;

  static void save(String token) => _token = token;

  static String? get token => _token;

  static void clear() => _token = null;
}
