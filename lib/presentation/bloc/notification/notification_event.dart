import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

class MarkNotificationRead extends NotificationEvent {
  const MarkNotificationRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsRead extends NotificationEvent {
  const MarkAllNotificationsRead();
}

class NotificationReceivedFromSocket extends NotificationEvent {
  const NotificationReceivedFromSocket(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}
