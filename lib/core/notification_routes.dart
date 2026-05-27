/// Maps FCM `data` payloads to GoRouter paths.
class NotificationRoutes {
  NotificationRoutes._();

  static String? routeFromData(Map<String, dynamic> data) {
    if (data.isEmpty) return null;

    final screen = data['screen']?.toString() ?? data['type']?.toString() ?? '';
    final lower = screen.toLowerCase();

    if (lower.contains('assignment') ||
        lower.contains('incident') ||
        lower.contains('dispatch') ||
        data['incident_id'] != null ||
        data['assignment_id'] != null) {
      return '/home';
    }
    if (lower == 'contacts') return '/contacts';
    if (lower == 'history') return '/history';
    if (lower == 'fleet') return '/fleet';
    if (lower == 'reports') return '/reports';
    if (lower == 'stats') return '/stats';
    if (lower == 'equipment') return '/equipment';
    if (lower == 'schedule') return '/schedule';

    return '/home';
  }
}
