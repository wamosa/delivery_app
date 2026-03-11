import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Future<User?> ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      return user;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }
}
