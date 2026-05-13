import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/patient/home_screen.dart';
import 'screens/paramedic/home_screen.dart';
import 'screens/dispatcher/home_screen.dart';
import 'services/auth_service.dart';

// Single shared AuthService instance for the router to avoid
// creating a new Dio client on every redirect callback invocation.
final _routerAuthService = AuthService();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isOnLoginPage = state.matchedLocation == '/login';
    final isOnRoleSelection = state.matchedLocation == '/role-selection';

    // If user is not logged in, redirect to login
    if (user == null) {
      return isOnLoginPage ? null : '/login';
    }

    // If user is logged in but on login page, redirect to home/role-selection
    if (isOnLoginPage) {
      try {
        final profile = await _routerAuthService.getUserProfile(user.uid);
        final role = profile['role'];
        if (role != null && role.isNotEmpty) {
          return '/home';
        } else {
          return '/role-selection';
        }
      } catch (_) {
        return '/role-selection';
      }
    }

    // If user is on role selection and already has a role, send to home
    if (isOnRoleSelection) {
      try {
        final profile = await _routerAuthService.getUserProfile(user.uid);
        final role = profile['role'];
        if (role != null && role.isNotEmpty) {
          return '/home';
        }
      } catch (_) {
        // User doesn't have a role yet, stay on role selection
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login',
    ),
  ],
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String?> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _getUserRole();
  }

  Future<String?> _getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final profile = await _routerAuthService.getUserProfile(user.uid);
      return profile['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userRoleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final role = snapshot.data;

        switch (role) {
          case 'patient':
            return const PatientHomeScreen();
          case 'paramedic':
            return const ParamedicHomeScreen();
          case 'dispatcher':
            return const DispatcherHomeScreen();
          default:
            return const RoleSelectionScreen();
        }
      },
    );
  }
}
