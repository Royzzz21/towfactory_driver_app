import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors_manager.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';

import 'presentation/bloc/booking/booking_bloc.dart';
import 'presentation/bloc/conversation/conversation_bloc.dart';
import 'presentation/bloc/notification/notification_bloc.dart';
import 'presentation/bloc/notification/notification_event.dart';
import 'presentation/bloc/session/session_bloc.dart';
import 'presentation/bloc/session/session_event.dart';
import 'presentation/router/app_router.dart';
import 'services/notification_service.dart';

/// Top-level handler for FCM messages received when app is in background or terminated.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM automatically shows the notification in the system tray for notification messages.
  // Nothing else needed here for background display.
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Register background FCM handler BEFORE Firebase.initializeApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase (gracefully skip if not yet configured)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[main] Firebase init skipped: $e');
  }

  await initServiceLocator();

  // Initialize FCM (registers token with API, sets up foreground notifications)
  try {
    await sl<NotificationService>().initialize();
  } catch (e) {
    debugPrint('[main] NotificationService init error: $e');
  }

  // Request location permission on app start
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }

  final router = getAppRouter();
  sl.registerSingleton<GoRouter>(router);
  runApp(MyApp(router: router));

  await Future.delayed(const Duration(seconds: 2));
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.statusBarBackground,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<SessionBloc>(
          create: (BuildContext context) =>
              sl<SessionBloc>()..add(const CheckSession()),
        ),
        BlocProvider<BookingBloc>(
          create: (_) => sl<BookingBloc>(),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => sl<ConversationBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => sl<NotificationBloc>()..add(const LoadNotifications()),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'DRIVER APP',
              routerConfig: router,
              theme: AppTheme().lightTheme,
              themeMode: ThemeMode.light,
            ),
          );
        },
      ),
    );
  }
}
