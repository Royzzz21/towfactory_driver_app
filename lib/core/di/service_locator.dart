import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:get_it/get_it.dart';

import '../../data/datasources/session_secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/storage/session_storage.dart';
import '../../domain/usecases/get_user_details_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/save_session_usecase.dart';
import '../../presentation/bloc/booking/booking_bloc.dart';
import '../../presentation/bloc/chat/chat_bloc.dart';
import '../../presentation/bloc/conversation/conversation_bloc.dart';
import '../../presentation/bloc/conversation_messages/conversation_messages_bloc.dart';
import '../../presentation/bloc/session/session_bloc.dart';
import '../../presentation/bloc/session/session_event.dart';
import '../../presentation/bloc/session/session_change_notifier.dart';
import '../../presentation/bloc/login/login_bloc.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../presentation/bloc/notification/notification_bloc.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/chat_websocket_service.dart';
import '../../services/driver_location_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/notification_service.dart';

final GetIt sl = GetIt.I;

const String _defaultBaseUrl = 'http://192.168.68.79:3001';
/// Socket.IO chat server (same port as API with /chats namespace)
const String _defaultSocketUrl = 'http://192.168.68.79:3001/chats';
/// Socket.IO driver location server (same port as API with /drivers namespace)
const String _defaultDriverSocketUrl = 'http://192.168.68.79:3001/drivers';
/// Socket.IO path (default for direct connection; overridden via env for reverse proxy)
const String _defaultSocketPath = '/socket.io/';

Future<void> initServiceLocator() async {
  // Secure session storage (Keychain / KeyStore)
  sl.registerLazySingleton<SessionStorage>(SessionSecureStorage.new);

  // Session repository (uses SessionStorage for MyUser)
  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(sl<SessionStorage>()),
  );

  // ApiService: central client with Bearer + 401 refresh/retry; on refresh fail → logout
  sl.registerLazySingleton<ApiService>(
    () => ApiService(
      baseUrl: dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl,
      sessionRepository: sl<SessionRepository>(),
      sessionStorage: sl<SessionStorage>(),
      refreshTokenCallback: (String rt) => sl<AuthRepository>().refreshToken(rt),
      onRefreshFailed: () => sl<SessionBloc>().add(const LogoutRequested()),
    ),
  );

  // Auth service (login/refresh raw http; getMe via ApiService for refresh handling)
  sl.registerLazySingleton<AuthService>(
    () => AuthService(
      baseUrl: dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl,
      apiService: sl<ApiService>(),
      sessionRepository: sl<SessionRepository>(),
    ),
  );

  // Booking service (GET /bookings/my via ApiService for auth + refresh)
  sl.registerLazySingleton<BookingService>(
    () => BookingService(sl<ApiService>()),
  );

  // Booking repository (uses BookingService)
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl<BookingService>()),
  );

  // Chat service (GET /chats/my via ApiService)
  sl.registerLazySingleton<ChatService>(
    () => ChatService(sl<ApiService>()),
  );

  // Chat repository (uses ChatService)
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<ChatService>()),
  );

  // Chat Socket.IO service (real-time chat with /chats namespace)
  sl.registerLazySingleton<ChatWebSocketService>(
    () => ChatWebSocketService(
      socketUrl: dotenv.env['SOCKET_URL'] ?? _defaultSocketUrl,
      sessionRepository: sl<SessionRepository>(),
      socketPath: dotenv.env['SOCKET_PATH'] ?? _defaultSocketPath,
    ),
  );

  // Driver location Socket.IO service (real-time GPS with /drivers namespace)
  sl.registerLazySingleton<DriverLocationService>(
    () => DriverLocationService(
      socketUrl: dotenv.env['DRIVER_SOCKET_URL'] ?? _defaultDriverSocketUrl,
      socketPath: dotenv.env['SOCKET_PATH'] ?? _defaultSocketPath,
    ),
  );

  // Notification API service (GET/PATCH /notifications + FCM token)
  sl.registerLazySingleton<NotificationApiService>(
    () => NotificationApiService(sl<ApiService>()),
  );

  // Notification repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<NotificationApiService>()),
  );

  // FCM manager (foreground notifications + token registration)
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(apiService: sl<NotificationApiService>()),
  );

  // Conversation repository (uses ChatRepository for GET /chats/my)
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(sl<ChatRepository>()),
  );

  // Auth repository (uses AuthService)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthService>()),
  );

  // Use cases
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<GetUserDetailsUsecase>(
    () => GetUserDetailsUsecase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SaveSessionUsecase>(
    () => SaveSessionUsecase(sl<SessionRepository>()),
  );

  // Session bloc (SaveSessionUsecase + SessionRepository + AuthRepository for refresh / auto-logout)
  sl.registerLazySingleton<SessionBloc>(
    () => SessionBloc(
      saveSessionUsecase: sl<SaveSessionUsecase>(),
      sessionRepository: sl<SessionRepository>(),
      sessionStorage: sl<SessionStorage>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Booking bloc (one per home; uses BookingRepository)
  sl.registerFactory<BookingBloc>(() => BookingBloc(sl<BookingRepository>()));

  // Chat bloc (uses ChatRepository)
  sl.registerFactory<ChatBloc>(() => ChatBloc(sl<ChatRepository>()));

  // Conversation bloc (uses ConversationRepository)
  sl.registerFactory<ConversationBloc>(() => ConversationBloc(sl<ConversationRepository>()));

  // Conversation messages bloc (per conversation; param1: bookingId, param2: bookingNumber for GET /chats/booking/number/:number)
  sl.registerFactoryParam<ConversationMessagesBloc, String, String>(
    (String bookingId, String bookingNumber) => ConversationMessagesBloc(
      sl<ChatRepository>(),
      sl<ChatWebSocketService>(),
      bookingId,
      bookingNumber,
    ),
  );

  // Notification bloc
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(sl<NotificationRepository>()),
  );

  // Login bloc (validation + LoginUsecase; one per screen)
  sl.registerFactory<LoginBloc>(() => LoginBloc(sl<LoginUsecase>()));

  // Session change notifier (listens to SessionBloc, notifies router)
  sl.registerLazySingleton<SessionChangeNotifier>(
    () => SessionChangeNotifier(sl<SessionBloc>()),
  );
}
