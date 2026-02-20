import 'package:equatable/equatable.dart';

import '../../../domain/entities/my_user.dart';

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final MyUser user;

  @override
  List<Object?> get props => [user];
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Emitted when login fails (e.g. invalid credentials).
class SessionError extends SessionState {
  const SessionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
