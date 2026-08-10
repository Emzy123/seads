import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seads/screens/dispatcher/home_screen.dart';
import 'package:seads/screens/dispatcher/fleet_management_screen.dart';
import 'package:seads/screens/dispatcher/incident_log_screen.dart';
import 'package:seads/screens/dispatcher/staff_management_screen.dart';

void main() {
  testWidgets('DispatcherHomeScreen renders without layout error on desktop/expanded screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DispatcherHomeScreen(),
        ),
      ),
    );

    expect(find.byType(DispatcherHomeScreen), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('FleetManagementScreen renders without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FleetManagementScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FleetManagementScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('IncidentLogScreen renders without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: IncidentLogScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(IncidentLogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaffManagementScreen renders without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StaffManagementScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(StaffManagementScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
