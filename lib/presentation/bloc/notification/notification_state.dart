import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded({
    required this.notifications,
    required this.hasMore,
    required this.unreadCount,
    this.currentPage = 1,
  });

  final List<AppNotification> notifications;
  final bool hasMore;
  final int unreadCount;
  final int currentPage;

  @override
  List<Object?> get props => [notifications, hasMore, unreadCount, currentPage];

  NotificationLoaded copyWith({
    List<AppNotification>? notifications,
    bool? hasMore,
    int? unreadCount,
    int? currentPage,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class NotificationError extends NotificationState {
  const NotificationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
