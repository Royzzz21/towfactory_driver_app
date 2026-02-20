import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/notification_api_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._service);

  final NotificationApiService _service;

  @override
  Future<List<AppNotification>> getNotifications({int page = 1, int limit = 20}) async {
    final map = await _service.getNotifications(page: page, limit: limit);
    final data = map['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markRead(String id) => _service.markRead(id);

  @override
  Future<void> markAllRead() => _service.markAllRead();

  @override
  Future<int> unreadCount() => _service.unreadCount();
}
