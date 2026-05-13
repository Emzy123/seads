import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'patient',
      'icon': Icons.home,
      'emoji': '🏠',
      'title': 'Patient',
      'description': 'I need emergency medical help',
      'color': const Color(0xFFE53935), // Urgent Red
    },
    {
      'value': 'paramedic',
      'icon': Icons.emergency,
      'emoji': '🚑',
      'title': 'Paramedic',
      'description': 'I respond to emergencies',
      'color': const Color(0xFF4CAF50), // Green
    },
    {
      'value': 'dispatcher',
      'icon': Icons.dashboard,
      'emoji': '🖥️',
      'title': 'Dispatcher',
      'description': 'I coordinate emergency response',
      'color': const Color(0xFF1E88E5), // Blue
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text(
                  'I am a...',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                const Text(
                  'Select your role to continue registration.',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['value'];
                    return _buildRoleCard(role, isSelected).animate().fadeIn(delay: (300 + (index * 100)).ms).slideY(begin: 0.2, end: 0);
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedRole != null ? () => context.go('/signup', extra: _selectedRole) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRole != null ? Theme.of(context).colorScheme.primary : Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role, bool isSelected) {
    final Color roleColor = role['color'];
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role['value']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? roleColor : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: roleColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: isSelected ? roleColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(role['emoji'], style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? roleColor : Colors.white)),
                        const SizedBox(height: 4),
                        Text(role['description'], style: const TextStyle(fontSize: 14, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? roleColor : Colors.white24,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
