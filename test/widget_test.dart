import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seads/screens/auth/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen shows hero content after splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
            GoRoute(path: '/role-selection', builder: (_, __) => const SizedBox.shrink()),
            GoRoute(path: '/login', builder: (_, __) => const SizedBox.shrink()),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('SEADS'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
