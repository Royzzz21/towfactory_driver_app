import 'package:equatable/equatable.dart';

import '../../../domain/entities/my_user.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);

  final MyUser user;

  @override
  List<Object?> get props => [user];
}

class LoginError extends LoginState {
  const LoginError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Validation failed; no API call. [formErrors] maps field name → error message.
class LoginFormErrors extends LoginState {
  const LoginFormErrors(this.formErrors);

  final Map<String, String> formErrors;

  @override
  List<Object?> get props => [formErrors];
}
