import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/storage/session_storage.dart';
import '../../../domain/usecases/save_session_usecase.dart';
import 'session_event.dart';
import 'session_state.dart';

/// Session state; persisted via [SaveSessionUsecase], restored on [CheckSession].
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required SaveSessionUsecase saveSessionUsecase,
    required SessionRepository sessionRepository,
    required SessionStorage sessionStorage,
    required AuthRepository authRepository,
  })  : _saveSessionUsecase = saveSessionUsecase,
        _sessionRepository = sessionRepository,
        _sessionStorage = sessionStorage,
        _authRepository = authRepository,
        super(const SessionInitial()) {
    on<CheckSession>(_onCheckSession);
    on<LogoutRequested>(_onLogoutRequested);
    on<SaveSessionEvent>(_onSaveSession);
    on<HandleUnauthorized>(_onHandleUnauthorized);
  }

  final SaveSessionUsecase _saveSessionUsecase;
  final SessionRepository _sessionRepository;
  final SessionStorage _sessionStorage;
  final AuthRepository _authRepository;

  Future<void> _onCheckSession(
    CheckSession event,
    Emitter<SessionState> emit,
  ) async {
    final user = await _sessionRepository.getStoredUser();
    if (user != null) {
      emit(SessionAuthenticated(user));
    } else {
      emit(const SessionUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _sessionStorage.clearSession();
    emit(const SessionUnauthenticated());
  }

  Future<void> _onSaveSession(
    SaveSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await _saveSessionUsecase.call(event.user);
    } catch (_) {
      // Still emit so UI can navigate; session may not persist across restarts
    }
    emit(SessionAuthenticated(event.user));
  }

  /// On 401 from an API: try refresh; if refresh fails (e.g. 401), auto-logout.
  Future<void> _onHandleUnauthorized(
    HandleUnauthorized event,
    Emitter<SessionState> emit,
  ) async {
    final user = await _sessionRepository.getStoredUser();
    if (user == null ||
        user.refreshToken == null ||
        user.refreshToken!.isEmpty) {
      await _sessionStorage.clearSession();
      emit(const SessionUnauthenticated());
      return;
    }
    try {
      final result = await _authRepository.refreshToken(user.refreshToken!);
      final updatedUser = user.copyWith(
        token: result.accessToken,
        refreshToken: result.refreshToken ?? user.refreshToken,
      );
      await _saveSessionUsecase.call(updatedUser);
      emit(SessionAuthenticated(updatedUser));
    } catch (_) {
      // Refresh failed (e.g. 401 Unauthorized) -> auto-logout
      await _sessionStorage.clearSession();
      emit(const SessionUnauthenticated());
    }
  }
}
