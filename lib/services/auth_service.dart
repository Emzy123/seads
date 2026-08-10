import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../core/auth_token_cache.dart';
import '../firebase_options.dart';
import '../models/user.dart' as app_model;
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  final Dio _restDio = Dio();

  static String? _restUid;
  static String? _restEmail;
  static String? _restToken;

  String? get currentUid => _firebaseAuth.currentUser?.uid ?? _restUid;
  String? get currentEmail => _firebaseAuth.currentUser?.email ?? _restEmail;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool get isAuthenticated => _firebaseAuth.currentUser != null || (_restUid != null && _restToken != null);

  Future<String?> getIdToken() async {
    final sdkToken = await _firebaseAuth.currentUser?.getIdToken();
    if (sdkToken != null) {
      AuthTokenCache.save(sdkToken);
      return sdkToken;
    }
    return _restToken ?? AuthTokenCache.token;
  }

  User? get currentUser => _firebaseAuth.currentUser;

  String get _apiKey => DefaultFirebaseOptions.currentPlatform.apiKey;

  Future<Map<String, dynamic>> _signUpViaRest(String email, String password) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';
    try {
      final res = await _restDio.post(url, data: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']?.toString() ?? e.message;
      if (msg == 'EMAIL_EXISTS') {
        throw Exception('The email address is already in use by another account.');
      } else if (msg == 'WEAK_PASSWORD' || msg == 'INVALID_PASSWORD') {
        throw Exception('Password should be at least 6 characters.');
      }
      throw Exception('Firebase auth error: $msg');
    }
  }

  Future<Map<String, dynamic>> _signInViaRest(String email, String password) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';
    try {
      final res = await _restDio.post(url, data: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']?.toString() ?? e.message;
      if (msg == 'EMAIL_NOT_FOUND' || msg == 'INVALID_LOGIN_CREDENTIALS' || msg == 'INVALID_PASSWORD') {
        throw Exception('Invalid email or password.');
      }
      throw Exception('Firebase auth error: $msg');
    }
  }

  // SIGN UP with email + password
  Future<app_model.User> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    String? uid;
    String? token;
    UserCredential? credential;

    try {
      // 1. Try Firebase Auth SDK
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = credential.user!.uid;
      token = await credential.user!.getIdToken();
    } catch (e) {
      final errStr = e.toString();
      final isNetworkError = errStr.contains('network-request-failed') ||
          errStr.contains('network_error') ||
          e is FirebaseAuthException;

      if (isNetworkError) {
        final restRes = await _signUpViaRest(email.trim(), password);
        uid = restRes['localId'] as String?;
        token = restRes['idToken'] as String?;
        _restUid = uid;
        _restEmail = email.trim();
        _restToken = token;
      } else {
        rethrow;
      }
    }

    if (uid == null) {
      throw Exception('Could not retrieve user ID after account creation.');
    }

    if (token != null) {
      AuthTokenCache.save(token);
    }

    // 2. Register in our backend
    try {
      final response = await _apiService.dio.post('/api/auth/register', data: {
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'phone': phone.trim(),
        'firebase_uid': uid,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return app_model.User.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to register: ${response.data}');
      }
    } on DioException catch (e) {
      if (credential != null && credential.user != null) {
        try {
          await credential.user!.delete();
        } catch (_) {}
      }
      if (e.response != null && e.response?.data != null) {
        final errorMsg = e.response?.data['error'] ?? e.response?.data.toString() ?? e.message;
        throw Exception('Server error: $errorMsg');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (credential != null && credential.user != null) {
        try {
          await credential.user!.delete();
        } catch (_) {}
      }
      throw Exception('Error creating account: $e');
    }
  }

  // LOGIN with email + password
  Future<app_model.User> signIn({
    required String email,
    required String password,
  }) async {
    String? uid;
    String? token;

    try {
      // 1. Firebase sign in
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = credential.user!.uid;
      token = await credential.user!.getIdToken();
    } catch (e) {
      final errStr = e.toString();
      final isNetworkError = errStr.contains('network-request-failed') ||
          errStr.contains('network_error') ||
          e is FirebaseAuthException;

      if (isNetworkError) {
        final restRes = await _signInViaRest(email.trim(), password);
        uid = restRes['localId'] as String?;
        token = restRes['idToken'] as String?;
        _restUid = uid;
        _restEmail = email.trim();
        _restToken = token;
      } else {
        rethrow;
      }
    }

    if (uid == null) {
      throw Exception('Could not retrieve user ID after sign in.');
    }

    if (token != null) {
      AuthTokenCache.save(token);
    }

    // 2. Get user from our backend
    try {
      final response = await _apiService.dio.post('/api/auth/login', data: {
        'email': email.trim(),
        'firebase_uid': uid,
      });

      if (response.statusCode == 200) {
        return app_model.User.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to login: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMsg = e.response?.data['error'] ?? e.response?.data.toString() ?? e.message;
        throw Exception('Server error: $errorMsg');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    _restUid = null;
    _restEmail = null;
    _restToken = null;
    AuthTokenCache.clear();
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Get user profile from backend
  Future<app_model.User> getUserProfile(String userId) async {
    try {
      final token = await getIdToken();
      final response = await _apiService.dio.get(
        '/api/users/$userId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final raw = Map<String, dynamic>.from(response.data as Map);
        final userJson = raw['user'] is Map
            ? Map<String, dynamic>.from(raw['user'] as Map)
            : raw;
        return app_model.User.fromJson(userJson);
      } else {
        throw Exception('Failed to get user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }
}
