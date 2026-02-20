import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({int page, int limit});
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<int> unreadCount();
}
