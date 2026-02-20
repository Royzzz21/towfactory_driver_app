import 'package:equatable/equatable.dart';

import '../../../domain/entities/my_user.dart';

/// Session bloc events.
abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class CheckSession extends SessionEvent {
  const CheckSession();
}

class LogoutRequested extends SessionEvent {
  const LogoutRequested();
}

/// Save logged-in user (after [LoginBloc] succeeds).
class SaveSessionEvent extends SessionEvent {
  const SaveSessionEvent(this.user);

  final MyUser user;

  @override
  List<Object?> get props => [user];
}

/// Called when an API returned 401. Tries refresh; if refresh fails, auto-logout.
class HandleUnauthorized extends SessionEvent {
  const HandleUnauthorized();
}
