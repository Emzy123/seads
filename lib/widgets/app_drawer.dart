import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final String userRole;
  final String activeRoute;
  final Color? accentColor;

  const AppDrawer({
    super.key,
    required this.userRole,
    required this.activeRoute,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              border: Border(
                right: BorderSide(color: color.withOpacity(0.3)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: color.withOpacity(0.2)),
                      ),
                    ),
                    child: userProfileAsync.when(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(
                              _getRoleIcon(),
                              size: 40,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading profile', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _buildMenuItems(context, color),
                    ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: color.withOpacity(0.2)),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          route: '/help',
                          color: color,
                          isActive: activeRoute == '/help',
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: Icons.settings,
                          label: 'Settings',
                          route: '/settings',
                          color: color,
                          isActive: activeRoute == '/settings',
                        ),
                        const Divider(color: Colors.white24),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                          onTap: () async {
                            await ref.read(authServiceProvider).signOut();
                            if (context.mounted) context.go('/welcome');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (userRole) {
      case 'patient':
        return Icons.person;
      case 'paramedic':
        return Icons.local_shipping;
      case 'dispatcher':
        return Icons.dashboard;
      default:
        return Icons.person;
    }
  }

  List<Widget> _buildMenuItems(BuildContext context, Color color) {
    final items = <Widget>[];

    // Role-specific menu items
    switch (userRole) {
      case 'patient':
        items.addAll([
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            label: 'Home',
            route: '/home',
            color: color,
            isActive: activeRoute == '/home',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            label: 'Emergency History',
            route: '/history',
            color: color,
            isActive: activeRoute == '/history',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.contacts,
            label: 'Emergency Contacts',
            route: '/contacts',
            color: color,
            isActive: activeRoute == '/contacts',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.medical_services,
            label: 'Medical Profile',
            route: '/medical-profile',
            color: color,
            isActive: activeRoute == '/medical-profile',
          ),
        ]);
        break;
      case 'paramedic':
        items.addAll([
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            label: 'Dashboard',
            route: '/home',
            color: color,
            isActive: activeRoute == '/home',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.assignment,
            label: 'Assignment History',
            route: '/assignment-history',
            color: color,
            isActive: activeRoute == '/assignment-history',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.bar_chart,
            label: 'Performance Stats',
            route: '/stats',
            color: color,
            isActive: activeRoute == '/stats',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.build,
            label: 'Equipment Check',
            route: '/equipment',
            color: color,
            isActive: activeRoute == '/equipment',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.schedule,
            label: 'Shift Schedule',
            route: '/schedule',
            color: color,
            isActive: activeRoute == '/schedule',
          ),
        ]);
        break;
      case 'dispatcher':
        items.addAll([
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            label: 'Command Center',
            route: '/home',
            color: color,
            isActive: activeRoute == '/home',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.local_shipping,
            label: 'Fleet Management',
            route: '/fleet',
            color: color,
            isActive: activeRoute == '/fleet',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.analytics,
            label: 'Reports & Analytics',
            route: '/reports',
            color: color,
            isActive: activeRoute == '/reports',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.people,
            label: 'Staff Management',
            route: '/staff',
            color: color,
            isActive: activeRoute == '/staff',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            label: 'Incident Log',
            route: '/incident-log',
            color: color,
            isActive: activeRoute == '/incident-log',
          ),
        ]);
        break;
    }

    return items;
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Color color,
    required bool isActive,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? color : Colors.white54,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? color : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? color.withOpacity(0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) {
          context.push(route);
        }
      },
    );
  }
}
