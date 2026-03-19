import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/entities/app_notification.dart';
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

  int _notifId = 0;

  final _foregroundMessageController = StreamController<AppNotification>.broadcast();

  /// Emits an [AppNotification] whenever an FCM message arrives while the app is in the foreground.
  Stream<AppNotification> get foregroundMessageStream => _foregroundMessageController.stream;

  void dispose() {
    _foregroundMessageController.close();
  }

  Future<void> initialize() async {
    // Request FCM permission (iOS prompts user, Android 13+ requires this)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: show banners/sound/badge while app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+: request POST_NOTIFICATIONS runtime permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create high-importance Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
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
      if (notification == null) return;

      // Build AppNotification from FCM payload and emit so HomeScreen can
      // prepend it to NotificationBloc without any API call.
      final appNotif = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: message.data['type'] as String? ?? 'booking_status',
        title: notification.title ?? '',
        body: notification.body ?? '',
        isRead: false,
        createdAt: (message.sentTime ?? DateTime.now()).toIso8601String(),
        data: message.data.isNotEmpty ? Map<String, dynamic>.from(message.data) : null,
      );
      _foregroundMessageController.add(appNotif);

      _localNotifications.show(
        id: _notifId++,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      if (kDebugMode) {
        print('[NotificationService] Foreground notification shown: ${notification.title}');
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
