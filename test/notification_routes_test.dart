import 'package:flutter_test/flutter_test.dart';
import 'package:seads/core/notification_routes.dart';

void main() {
  test('routes assignment payload to home', () {
    expect(
      NotificationRoutes.routeFromData({'type': 'assignment', 'incident_id': '1'}),
      '/home',
    );
  });

  test('routes contacts screen', () {
    expect(NotificationRoutes.routeFromData({'screen': 'contacts'}), '/contacts');
  });

  test('returns null for empty data', () {
    expect(NotificationRoutes.routeFromData({}), isNull);
  });
}
