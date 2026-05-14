import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../models/user.dart' as app_model;
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // SIGN UP with email + password
  Future<app_model.User> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    try {
      // 1. Create Firebase account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Register in our backend
      final response = await _apiService.dio.post('/api/auth/register', data: {
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'phone': phone.trim(),
        'firebase_uid': credential.user!.uid,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return app_model.User.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to register: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMsg = e.response?.data['error'] ?? e.response?.data.toString() ?? e.message;
        throw Exception('Server error: $errorMsg');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error creating account: $e');
    }
  }

  // LOGIN with email + password
  Future<app_model.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase sign in
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Get user from our backend
      final response = await _apiService.dio.post('/api/auth/login', data: {
        'email': email.trim(),
        'firebase_uid': credential.user!.uid,
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
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Get ID token for API calls
  Future<String?> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken();
  }

  // Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

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
