import '../entities/my_user.dart';
import '../entities/session.dart';

/// Abstraction for persisting session (e.g. secure storage).
abstract class SessionStorage {
  /// Returns the stored session, or null if none.
  Future<Session?> getSession();

  /// Saves the session (e.g. after login).
  Future<void> saveSession(Session session);

  /// Saves user + token (for [SessionRepository.saveSession]).
  Future<void> saveUserAndToken(MyUser user);

  /// Returns the stored [MyUser], or null if none.
  Future<MyUser?> getStoredUser();

  /// Clears the stored session (e.g. on logout).
  Future<void> clearSession();
}
