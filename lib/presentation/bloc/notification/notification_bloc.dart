import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/api_exception.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<NotificationReceivedFromSocket>(_onSocketNotification);
  }

  final NotificationRepository _repository;
  static const int _pageSize = 20;

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // If already loaded, skip the Loading state so the badge doesn't flash to 0
    final current = state;
    if (current is! NotificationLoaded) emit(const NotificationLoading());
    try {
      final notifications = await _repository.getNotifications(page: 1, limit: _pageSize);
      final count = await _repository.unreadCount();
      emit(NotificationLoaded(
        notifications: notifications,
        hasMore: notifications.length == _pageSize,
        unreadCount: count,
        currentPage: 1,
      ));
    } catch (e) {
      emit(NotificationError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded || !current.hasMore) return;
    try {
      final nextPage = current.currentPage + 1;
      final more = await _repository.getNotifications(page: nextPage, limit: _pageSize);
      emit(current.copyWith(
        notifications: [...current.notifications, ...more],
        hasMore: more.length == _pageSize,
        currentPage: nextPage,
      ));
    } catch (_) {}
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded) return;
    try {
      await _repository.markRead(event.id);
      final wasUnread = current.notifications.any((n) => n.id == event.id && !n.isRead);
      final updated = current.notifications
          .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(current.copyWith(
        notifications: updated,
        unreadCount: wasUnread ? (current.unreadCount - 1).clamp(0, 9999) : current.unreadCount,
      ));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded) return;
    try {
      await _repository.markAllRead();
      emit(current.copyWith(
        notifications: current.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      ));
    } catch (_) {}
  }

  void _onSocketNotification(
    NotificationReceivedFromSocket event,
    Emitter<NotificationState> emit,
  ) {
    final current = state;
    if (current is NotificationLoaded) {
      emit(current.copyWith(
        notifications: [event.notification, ...current.notifications],
        unreadCount: current.unreadCount + 1,
      ));
    } else {
      emit(NotificationLoaded(
        notifications: [event.notification],
        hasMore: false,
        unreadCount: 1,
      ));
    }
  }
}
