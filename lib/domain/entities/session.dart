import 'package:equatable/equatable.dart';

import 'user.dart';

/// Domain entity representing the current session (auth state).
class Session extends Equatable {
  Session({
    required this.token,
    this.refreshToken,
    this.user,
    String? userId,
  }) : userId = userId ?? user?.id ?? '';

  /// Access token for API requests.
  final String token;

  /// Optional refresh token for renewing access.
  final String? refreshToken;

  /// User details from login response (optional).
  final User? user;

  /// User id (from [user.id] or legacy).
  final String userId;

  @override
  List<Object?> get props => [userId, token, refreshToken, user];
}
