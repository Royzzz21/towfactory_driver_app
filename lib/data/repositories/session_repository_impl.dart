import '../../domain/entities/my_user.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/storage/session_storage.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._storage);

  final SessionStorage _storage;

  @override
  Future<void> saveSession(MyUser user) => _storage.saveUserAndToken(user);

  @override
  Future<MyUser?> getStoredUser() => _storage.getStoredUser();
}
