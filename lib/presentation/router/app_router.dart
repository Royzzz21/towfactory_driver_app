import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/chat.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_state.dart';
import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_change_notifier.dart';
import '../bloc/session/session_state.dart';
import '../bloc/login/login_bloc.dart';
import '../screens/booking_details/booking_details_screen.dart';
import '../bloc/conversation_messages/conversation_messages_bloc.dart';
import '../screens/conversation/conversation_messages_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Route names/paths.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String bookingDetails = '/booking/:id';
  static const String conversation = '/conversation';

  /// Paths that require authentication (token must exist).
  static const List<String> privatePaths = [home];

  /// Paths that don't require authentication.
  static const List<String> publicPaths = [splash, login];

  /// Returns true if [path] is a public route (no auth required).
  static bool isPublicRoute(String path) =>
      publicPaths.contains(path) || path.isEmpty;

  /// Returns true if [path] is a private route (token required).
  static bool isPrivateRoute(String path) =>
      privatePaths.contains(path) || path.isEmpty;

  /// Returns true if [path] is under /booking (requires auth).
  static bool isBookingPath(String path) => path.startsWith('/booking');

  /// Returns true if [path] is under /conversation (requires auth).
  static bool isConversationPath(String path) => path.startsWith('/conversation');
}

GoRouter getAppRouter() {
  final sessionChangeNotifier = sl<SessionChangeNotifier>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: sessionChangeNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      // Use sl<> so redirect works even when context has no BlocProvider in scope
      final sessionBloc = sl<SessionBloc>();
      final sessionState = sessionBloc.state;
      final currentPath = state.uri.path;
      final hasToken = sessionState is SessionAuthenticated;

      // Splash: let splash screen handle navigation to home
      if (currentPath == AppRoutes.splash) return null;

      // Still loading / initial: stay on current route
      if (sessionState is SessionInitial) {
        return null;
      }

      // Token exists: allow private routes and /booking/*; if on login, go home
      if (hasToken) {
        if (AppRoutes.isPublicRoute(currentPath)) {
          return AppRoutes.home;
        }
        return null;
      }

      // No token: redirect to login if on private route, booking or conversation
      if (sessionState is SessionUnauthenticated) {
        if (AppRoutes.isPrivateRoute(currentPath) ||
            AppRoutes.isBookingPath(currentPath) ||
            AppRoutes.isConversationPath(currentPath)) {
          return AppRoutes.login;
        }
        return null;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return HomeScreen(title: 'DRIVER APP');
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<LoginBloc>(
            create: (BuildContext context) => sl<LoginBloc>(),
            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookingDetails,
        name: 'bookingDetails',
        builder: (BuildContext context, GoRouterState state) {
          final booking = state.extra as Booking?;
          if (booking == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Booking')),
              body: const Center(child: Text('Booking not found')),
            );
          }
          return BlocListener<BookingBloc, BookingState>(
            listener: (BuildContext context, BookingState state) {
              if (state is ArrivedBookingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state is CancelBookingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.pop();
              }
            },
            child: BookingDetailsScreen(booking: booking),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.conversation,
        name: 'conversation',
        builder: (BuildContext context, GoRouterState state) {
          final chat = state.extra as Chat?;
          if (chat == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Conversation')),
              body: const Center(child: Text('Conversation not found')),
            );
          }
          final bookingId = chat.bookingId ?? chat.id;
          final bookingNumber = chat.bookingNumber ?? chat.bookingId ?? chat.id;
          final bloc = sl<ConversationMessagesBloc>(param1: bookingId, param2: bookingNumber);
          return BlocProvider<ConversationMessagesBloc>.value(
            value: bloc,
            child: ConversationMessagesScreen(chat: chat),
          );
        },
      ),
    ],
  );
}
