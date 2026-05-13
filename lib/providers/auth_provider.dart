import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_model;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = FutureProvider<app_model.User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) return null;
  
  return await authService.getUserProfile(user.uid);
});
