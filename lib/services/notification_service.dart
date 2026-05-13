import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not inside a class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  final _foregroundController = StreamController<RemoteMessage>.broadcast();
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;
  Stream<Map<String, dynamic>> get notificationTaps => _tapController.stream;

  /// Call once at app startup after Firebase.initializeApp()
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');

    // Save initial token to backend
    await _saveTokenToBackend();

    // Re-save token on refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed');
      _apiService.saveFcmToken(token);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}');
      _foregroundController.add(message);
    });

    // Background notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _tapController.add(message.data);
    });

    // Terminated state — app opened via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _tapController.add(initialMessage.data);
    }
  }

  Future<void> _saveTokenToBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Saving token to backend');
        await _apiService.saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  void dispose() {
    _foregroundController.close();
    _tapController.close();
  }
}
