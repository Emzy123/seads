import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_complete_screen.dart';
import 'screens/patient/home_screen.dart';
import 'screens/patient/emergency_history_screen.dart';
import 'screens/patient/emergency_contacts_screen.dart';
import 'screens/patient/medical_profile_screen.dart';
import 'screens/paramedic/home_screen.dart';
import 'screens/paramedic/assignment_history_screen.dart';
import 'screens/paramedic/performance_stats_screen.dart';
import 'screens/paramedic/equipment_check_screen.dart';
import 'screens/paramedic/shift_schedule_screen.dart';
import 'screens/dispatcher/home_screen.dart';
import 'screens/dispatcher/fleet_management_screen.dart';
import 'screens/dispatcher/reports_analytics_screen.dart';
import 'screens/dispatcher/staff_management_screen.dart';
import 'screens/dispatcher/incident_log_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/help_screen.dart';
import 'services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  redirect: (BuildContext context, GoRouterState state) async {
    final authService = AuthService();
    final isAuthenticated = authService.isAuthenticated;

    // Pages that require the user to be logged OUT
    final isOnAuthPage = state.matchedLocation.startsWith('/welcome') ||
                         state.matchedLocation.startsWith('/login') ||
                         state.matchedLocation.startsWith('/signup') ||
                         state.matchedLocation.startsWith('/role-selection');

    // /onboarding-complete is intentionally excluded from the redirect:
    // a newly registered user IS logged in but must still see this screen
    // before being sent to their role-specific dashboard.
    final isOnOnboarding = state.matchedLocation.startsWith('/onboarding-complete');

    // If user is not logged in, redirect to welcome (except auth pages)
    if (!isAuthenticated && !isOnAuthPage && !isOnOnboarding) {
      return '/welcome';
    }

    // If user is logged in and on a pure-auth page (not onboarding), send home
    if (isAuthenticated && isOnAuthPage) {
      return '/home';
    }

    return null;
  },
  routes: [
    // Auth routes
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignUpScreen(
        role: state.extra as String? ?? 'patient',
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding-complete',
      builder: (context, state) => OnboardingCompleteScreen(
        user: state.extra as dynamic,
      ),
    ),
    
    // Protected routes - Patient
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const EmergencyHistoryScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const EmergencyContactsScreen(),
    ),
    GoRoute(
      path: '/medical-profile',
      builder: (context, state) => const MedicalProfileScreen(),
    ),

    // Protected routes - Paramedic
    GoRoute(
      path: '/assignment-history',
      builder: (context, state) => const AssignmentHistoryScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const PerformanceStatsScreen(),
    ),
    GoRoute(
      path: '/equipment',
      builder: (context, state) => const EquipmentCheckScreen(),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const ShiftScheduleScreen(),
    ),

    // Protected routes - Dispatcher
    GoRoute(
      path: '/fleet',
      builder: (context, state) => const FleetManagementScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsAnalyticsScreen(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffManagementScreen(),
    ),
    GoRoute(
      path: '/incident-log',
      builder: (context, state) => const IncidentLogScreen(),
    ),

    // Shared routes
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),

    GoRoute(
      path: '/',
      redirect: (context, state) => '/welcome',
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
    final authService = AuthService();
    final uid = authService.currentUid;
    if (uid == null) return null;
    final profile = await authService.getUserProfile(uid);
    return profile.role;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userRoleFuture,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E1A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Error or unauthenticated
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load your profile.',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your connection and try again.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () => setState(() {
                        _userRoleFuture = _getUserRole();
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/welcome'),
                      child: const Text('Sign out and try again', style: TextStyle(color: Colors.white38)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        switch (snapshot.data) {
          case 'patient':
            return const PatientHomeScreen();
          case 'paramedic':
            return const ParamedicHomeScreen();
          case 'dispatcher':
            return const DispatcherHomeScreen();
          default:
            // Unknown role — sign out and return to welcome
            FirebaseAuth.instance.signOut();
            return const RoleSelectionScreen();
        }
      },
    );
  }
}
