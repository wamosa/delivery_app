import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthController {
  AuthController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  Future<AuthUser> loadUser() {
    return _repository.getCurrentUser();
  }

  Stream<AuthUser> watchUser() {
    return _repository.watchCurrentUser();
  }

  Future<void> saveUser(AuthUser user) {
    return _repository.saveUser(user);
  }
}
