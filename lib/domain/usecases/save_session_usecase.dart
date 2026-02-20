import '../entities/my_user.dart';
import '../repositories/session_repository.dart';

/// Use case: persist session by saving [MyUser] (user + token) via [SessionRepository].
class SaveSessionUsecase {
  SaveSessionUsecase(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<void> call(MyUser user) => _sessionRepository.saveSession(user);
}
