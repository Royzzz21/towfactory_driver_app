import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../services/driver_location_service.dart';
import '../../bloc/booking/booking_bloc.dart';
import '../../bloc/booking/booking_event.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';
import '../../bloc/session/session_bloc.dart';
import '../../bloc/session/session_event.dart';
import '../../bloc/session/session_state.dart';
import 'tabs/booking_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/notification_tab.dart';
import 'tabs/user_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription? _notifSub;

  // Stable instances — created once so initState of each tab fires only once.
  static const _bookingTab = BookingTab();
  static const _chatTab = ChatTab();
  static const _notificationTab = NotificationTab();

  static const int _userTabIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Connect socket and start GPS tracking immediately after login
    final session = context.read<SessionBloc>().state;
    if (session is SessionAuthenticated) {
      final locationService = sl<DriverLocationService>();
      locationService.connect(session.user.id);
      if (!locationService.isTracking) {
        locationService.start(session.user.id);
      }
    }

    // Bridge socket notifications → NotificationBloc
    // Also refetch bookings when a new booking is assigned via socket
    _notifSub = sl<DriverLocationService>().notificationStream.listen((n) {
      if (!mounted) return;
      context.read<NotificationBloc>().add(NotificationReceivedFromSocket(n));
      if (n.type == 'booking_assigned' || n.type == 'booking_available') {
        final sessionState = context.read<SessionBloc>().state;
        if (sessionState is SessionAuthenticated) {
          context.read<BookingBloc>().add(RefreshBookings(driverId: sessionState.user.id));
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    super.dispose();
  }

  /// Refetch bookings when the app comes back to the foreground —
  /// covers the case where an FCM notification arrived while the app was
  /// in the background and the socket was disconnected.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final sessionState = context.read<SessionBloc>().state;
      if (sessionState is SessionAuthenticated) {
        context.read<BookingBloc>().add(RefreshBookings(driverId: sessionState.user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                sl<DriverLocationService>().disconnect();
                context.read<SessionBloc>().add(const LogoutRequested());
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _bookingTab,
          _chatTab,
          _notificationTab,
          UserTab(
            isSelected: _currentIndex == _userTabIndex,
            tabIndex: _userTabIndex,
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (int index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Booking',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (ctx, state) {
                  final count = state is NotificationLoaded ? state.unreadCount : 0;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.notifications_rounded),
                  );
                },
              ),
              label: 'Notification',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'User',
            ),
          ],
        ),
      ),
    );
  }
}
