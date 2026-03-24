import 'package:firebase_auth/firebase_auth.dart';

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

  Stream<User?> authStateChanges() {
    return _repository.authStateChanges();
  }

  Stream<AuthUser?> watchAuthUser() {
    return _repository.watchAuthUser();
  }

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) {
    return _repository.registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<void> signOut() {
    return _repository.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
