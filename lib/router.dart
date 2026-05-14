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
import 'services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isOnAuthPage = state.matchedLocation.startsWith('/welcome') ||
                        state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/signup') ||
                        state.matchedLocation.startsWith('/role-selection') ||
                        state.matchedLocation.startsWith('/onboarding-complete');

    // If user is not logged in, redirect to welcome
    if (user == null && !isOnAuthPage) {
      return '/welcome';
    }

    // If user is logged in but on auth page, redirect to home
    if (user != null && isOnAuthPage) {
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
      builder: (context, state) => const Scaffold(body: Center(child: Text('Settings - Coming Soon'))),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const Scaffold(body: Center(child: Text('Help & Support - Coming Soon'))),
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final authService = AuthService();
      final profile = await authService.getUserProfile(user.uid);
      return profile.role;
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
