import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/seads_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportPhone = '+23480073237';
  static const _supportEmail = 'support@seads.app';

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open $uri');
    }
  }

  Future<void> _openLink(String url) => _launch(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    return SeadsScaffold(
      title: 'Help & Support',
      accentColor: AppTheme.criticalTeal,
      body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Emergency', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Text(
                'For life-threatening emergencies, call your local emergency number (e.g. 911) immediately. SEADS supplements — it does not replace — official emergency services.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text('Using SEADS', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              _faq(
                'How do I request an ambulance?',
                'On the patient home screen, hold the red SOS button for about 3 seconds, then confirm. You can also tap "Request help" for the same confirmation without holding.',
              ),
              _faq(
                'Who sees my location?',
                'Your location is shared with dispatch and assigned paramedics only during an active emergency request.',
              ),
              _faq(
                'Forgot password?',
                'Use "Forgot password" on the login screen, or contact support below.',
              ),
              const SizedBox(height: 24),
              Text('Contact support', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              _actionTile(
                context,
                icon: Icons.phone,
                label: 'Call SEADS support',
                onTap: () => _launch(Uri.parse('tel:$_supportPhone')),
              ),
              _actionTile(
                context,
                icon: Icons.email_outlined,
                label: _supportEmail,
                onTap: () => _launch(Uri.parse('mailto:$_supportEmail')),
              ),
              const SizedBox(height: 24),
              Text('Legal', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              _actionTile(
                context,
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                onTap: () => _openLink('https://seads.app/privacy'),
              ),
              _actionTile(
                context,
                icon: Icons.description_outlined,
                label: 'Terms of service',
                onTap: () => _openLink('https://seads.app/terms'),
              ),
            ],
          ),
    );
  }

  Widget _faq(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(a, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
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
        title: Text(label, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary)),
        trailing: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
        onTap: () async {
          try {
            await onTap();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open link: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
