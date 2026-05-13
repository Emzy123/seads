import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  final User user;
  
  const OnboardingCompleteScreen({super.key, required this.user});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  String _getRoleSpecificMessage() {
    switch (widget.user.role) {
      case 'patient': return 'Press the SOS button when you need help. We\'ll find the nearest ambulance and get you the care you need quickly.';
      case 'paramedic': return 'Stay on duty to receive emergency dispatch alerts. Your quick response saves lives every day.';
      case 'dispatcher': return 'Monitor live incidents and coordinate emergency responses. You\'re the critical link between patients and care.';
      default: return 'Welcome to SEADS emergency response system.';
    }
  }

  String _getRoleSpecificTitle() {
    switch (widget.user.role) {
      case 'patient': return 'Ready for Emergency Care';
      case 'paramedic': return 'Ready to Save Lives';
      case 'dispatcher': return 'Ready to Coordinate';
      default: return 'All Set Up';
    }
  }

  Color _getRoleColor() {
    switch (widget.user.role) {
      case 'patient': return const Color(0xFFE53935);
      case 'paramedic': return const Color(0xFF4CAF50);
      case 'dispatcher': return const Color(0xFF1E88E5);
      default: return Colors.white;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.user.role) {
      case 'patient': return Icons.home;
      case 'paramedic': return Icons.emergency;
      case 'dispatcher': return Icons.dashboard;
      default: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated checkmark/icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: roleColor.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)],
                ),
                child: const Icon(Icons.check, size: 80, color: Colors.white),
              ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 1.seconds),
              
              const SizedBox(height: 32),
              
              Text('You\'re all set, ${widget.user.name}!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 8),
              
              Text(_getRoleSpecificTitle(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: roleColor), textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 32),
              
              // Role-specific message card
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(_getRoleIcon(), size: 40, color: roleColor),
                        const SizedBox(height: 16),
                        Text(_getRoleSpecificMessage(), style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
              
              const Spacer(flex: 2),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Go to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
