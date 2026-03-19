import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/app_notification.dart';
import '../../../bloc/notification/notification_bloc.dart';
import '../../../bloc/notification/notification_event.dart';
import '../../../bloc/notification/notification_state.dart';

/// Full notification tab — shows paginated list with unread indicators,
/// mark-all-read action, and pull-to-refresh.
///
/// [isSelected] must be true when this tab is actively visible so that
/// unread notifications are only marked read when the user is actually here.
class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key, required this.isSelected});

  final bool isSelected;

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllReadIfLoaded();
    });
  }

  void _markAllReadIfLoaded() {
    if (!widget.isSelected) return;
    final bloc = context.read<NotificationBloc>();
    final state = bloc.state;
    if (state is NotificationLoaded && state.unreadCount > 0) {
      bloc.add(const MarkAllNotificationsRead());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<NotificationBloc>().add(const LoadMoreNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (widget.isSelected && state is NotificationLoaded && state.unreadCount > 0) {
          context.read<NotificationBloc>().add(const MarkAllNotificationsRead());
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(const LoadNotifications());
                },
                child: _buildBody(context, state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.message, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<NotificationBloc>().add(const LoadNotifications()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
        itemBuilder: (context, index) {
          if (index >= state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _NotificationCard(notification: state.notifications[index]);
        },
      );
    }

    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationBloc>().add(MarkNotificationRead(notification.id));
        }
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(notification.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData(notification.type),
                size: 20,
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconData(String type) {
    switch (type) {
      case 'booking_assigned':
        return Icons.assignment_ind_rounded;
      case 'booking_status':
        return Icons.update_rounded;
      case 'new_chat_message':
        return Icons.chat_rounded;
      case 'booking_available':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'booking_assigned':
        return Colors.green;
      case 'booking_status':
        return Colors.orange;
      case 'new_chat_message':
        return Colors.blue;
      case 'booking_available':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _relativeTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (_) {
      return '';
    }
  }
}
