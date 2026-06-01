import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../config.dart';
import '../core/auth_token_cache.dart';

/// Paramedic background GPS — foreground service on Android when on duty.
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._();

  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundLocationOnStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'seads_location',
        initialNotificationTitle: 'SEADS',
        initialNotificationContent: 'Sharing location while on duty',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: backgroundLocationOnStart,
        onBackground: backgroundLocationOnIosBackground,
      ),
    );
    _configured = true;
  }

  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  Future<void> startIfNeeded() async {
    await configure();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return;
    await service.startService();
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stop');
    }
  }
}

@pragma('vm:entry-point')
void backgroundLocationOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('stop').listen((_) => service.stopSelf());
    service.setAsForegroundService();
  }

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.backendUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  StreamSubscription<Position>? sub;
  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    ),
  ).listen((position) async {
    final token = AuthTokenCache.token;
    if (token == null) return;
    try {
      await dio.put(
        '/api/ambulances/location',
        data: {'lat': position.latitude, 'lng': position.longitude},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
  });

  service.on('stop').listen((_) async {
    await sub?.cancel();
    await service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> backgroundLocationOnIosBackground(ServiceInstance service) async {
  return true;
}
