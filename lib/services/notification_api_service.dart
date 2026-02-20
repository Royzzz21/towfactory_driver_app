import 'dart:convert';

import 'api_service.dart';

/// API calls for notifications + FCM token registration.
class NotificationApiService {
  NotificationApiService(this._apiService);

  final ApiService _apiService;

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final body = await _apiService.get(
      '/notifications',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    return json.decode(body) as Map<String, dynamic>;
  }

  Future<void> markRead(String id) async {
    await _apiService.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _apiService.patch('/notifications/read-all');
  }

  Future<int> unreadCount() async {
    final body = await _apiService.get('/notifications/unread-count');
    final decoded = json.decode(body) as Map<String, dynamic>;
    return decoded['count'] as int? ?? 0;
  }

  Future<void> updateFcmToken(String? token) async {
    await _apiService.patch(
      '/users/me/fcm-token',
      body: json.encode({'fcmToken': token}),
    );
  }
}
