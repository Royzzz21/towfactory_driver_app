import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/form_validator.dart';
import '../../../domain/core/api_exception.dart';
import '../../../domain/entities/login_request.dart';
import '../../../domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Handles sign-in: validation (FormValidator) then LoginUsecase.
/// On success emits [LoginSuccess]([MyUser]); on validation failure [LoginFormErrors]; on API failure [LoginError].
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUsecase) : super(const LoginInitial()) {
    on<SignWithEmailEvent>(_onSignWithEmail);
  }

  final LoginUsecase _loginUsecase;

  Future<void> _onSignWithEmail(
    SignWithEmailEvent event,
    Emitter<LoginState> emit,
  ) async {
    final formErrors = FormValidator.validateLogin(
      email: event.email,
      password: event.password,
    );

    if (formErrors.isNotEmpty) {
      emit(LoginFormErrors(formErrors));
      return;
    }

    emit(const LoginLoading());

    try {
      final payload = LoginRequest(
        email: event.email.trim(),
        password: event.password,
      );
      final user = await _loginUsecase.call(payload).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Login timed out'),
      );

      print('user: $user');
      emit(LoginSuccess(user));
    } on TimeoutException catch (_) {
      emit(const LoginError('Request timed out. Check your connection.'));
    } on ApiException catch (e) {
      if (e.statusCode == 422 && e.errors != null && e.errors!.isNotEmpty) {
        final formErrors = _errorsToFormErrors(e.errors!);
        if (formErrors.isNotEmpty) {
          emit(LoginFormErrors(formErrors));
          return;
        }
      }
      emit(LoginError(e.message));
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }

  /// Converts API 422 errors map to [LoginFormErrors] map (field name → message).
  /// Handles both { "email": "msg" } and { "email": ["msg1", "msg2"] }.
  static Map<String, String> _errorsToFormErrors(Map<String, dynamic> errors) {
    final result = <String, String>{};
    for (final entry in errors.entries) {
      final key = entry.key;
      final value = entry.value;
      String? message;
      if (value is String) {
        message = value;
      } else if (value is List<dynamic> && value.isNotEmpty) {
        message = value.first.toString();
      }
      if (message != null && message.isNotEmpty) {
        result[key] = message;
      }
    }
    return result;
  }
}
