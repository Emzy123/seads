import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'core/notification_routes.dart';
import 'core/offline_queue.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await OfflineQueue.init();
  await NotificationService().initialize();
  try {
    await OfflineQueue.processAll(ApiService());
  } catch (_) {}

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().notificationTaps.listen(_onNotificationTap);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onNotificationTap(Map<String, dynamic> data) {
    final route = NotificationRoutes.routeFromData(data);
    if (route != null) {
      appRouter.go(route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      OfflineQueue.processAll(ApiService()).then((n) {
        if (n > 0 && mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text('Synced $n queued update${n == 1 ? '' : 's'}')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SEADS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightThemeData(),
      darkTheme: AppTheme.buildThemeData(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
