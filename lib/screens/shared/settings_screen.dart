import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/seads_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _auth = AuthService();
  String? _email;
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _email = _auth.currentEmail);
    try {
      final profile = await _auth.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _role = profile.role;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Sign out?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'You will need to sign in again to use SEADS.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _auth.signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return SeadsScaffold(
      title: 'Settings',
      accentColor: AppTheme.criticalTeal,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.criticalTeal))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _sectionTitle('Account'),
                _tile(
                  icon: Icons.person_outline,
                  title: _email ?? 'Not signed in',
                  subtitle: _role != null ? 'Role: $_role' : null,
                ),
                _sectionTitle('Appearance'),
                _tile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  subtitle: _themeModeLabel(themeMode),
                  onTap: () => _showThemePicker(themeMode),
                ),
                _sectionTitle('App'),
                _tile(
                  icon: Icons.cloud_outlined,
                  title: 'Environment',
                  subtitle: '${AppConfig.env}${AppConfig.isDemoMode ? ' · demo data enabled' : ''}',
                ),
                _tile(
                  icon: Icons.link,
                  title: 'API server',
                  subtitle: AppConfig.backendUrl,
                ),
                _sectionTitle('Support'),
                _tile(
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  onTap: () => context.push('/help'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.criticalRed,
                      side: const BorderSide(color: AppTheme.criticalRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showThemePicker(ThemeMode current) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System', style: TextStyle(color: AppTheme.textPrimary)),
              trailing: current == ThemeMode.system ? const Icon(Icons.check, color: AppTheme.criticalTeal) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.system),
            ),
            ListTile(
              title: const Text('Light', style: TextStyle(color: AppTheme.textPrimary)),
              trailing: current == ThemeMode.light ? const Icon(Icons.check, color: AppTheme.criticalTeal) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.light),
            ),
            ListTile(
              title: const Text('Dark', style: TextStyle(color: AppTheme.textPrimary)),
              trailing: current == ThemeMode.dark ? const Icon(Icons.check, color: AppTheme.criticalTeal) : null,
              onTap: () => Navigator.pop(ctx, ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      ref.read(themeModeProvider.notifier).state = selected;
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: AppTheme.bodySmall.copyWith(color: AppTheme.criticalTeal)),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: AppTheme.glassBackground,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.criticalTeal),
        title: Text(title, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle, style: AppTheme.bodySmall)
            : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppTheme.textMuted) : null,
        onTap: onTap,
      ),
    );
  }
}
