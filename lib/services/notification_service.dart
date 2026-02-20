import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_api_service.dart';

/// Manages FCM push notifications:
/// - Requests permission
/// - Registers FCM token with the API
/// - Shows foreground notifications via flutter_local_notifications
///
/// NOTE: Firebase must be initialized (Firebase.initializeApp) before calling [initialize].
class NotificationService {
  NotificationService({required NotificationApiService apiService})
      : _apiService = apiService;

  final NotificationApiService _apiService;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'driver_notifications';
  static const _channelName = 'Driver Notifications';

  Future<void> initialize() async {
    // Request permission (iOS prompts user, Android 13+ requires this)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create high-importance Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get token and register with API
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);

    // Re-register on token refresh
    _messaging.onTokenRefresh.listen(_registerToken);

    // Show local notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiService.updateFcmToken(token);
      if (kDebugMode) print('[NotificationService] FCM token registered');
    } catch (e) {
      if (kDebugMode) print('[NotificationService] token registration error: $e');
    }
  }
}
