import '../entities/my_user.dart';

/// Repository for persisting session (save user + token).
abstract class SessionRepository {
  /// Saves the logged-in user (and token) to storage.
  Future<void> saveSession(MyUser user);

  /// Returns the stored user, or null if none.
  Future<MyUser?> getStoredUser();
}
