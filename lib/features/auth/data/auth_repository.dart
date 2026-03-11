import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<AuthUser> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('No signed-in Firebase user was found.');
    }

    final userId = firebaseUser.uid;
    final doc =
        await _firestore.collection(FirestorePaths.users).doc(userId).get();

    if (doc.exists) {
      return AuthUser.fromFirestore(doc);
    }

    final fallbackUser = AuthUser(
      id: userId,
      name: firebaseUser.displayName ?? 'Guest Customer',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email ?? 'anonymous@ayeyo.app',
      role: 'customer',
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .set(fallbackUser.toMap());
    return fallbackUser;
  }

  Stream<AuthUser> watchCurrentUser() async* {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('No signed-in Firebase user was found.');
    }

    final userId = firebaseUser.uid;
    await getCurrentUser();

    yield* _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .snapshots()
        .map((doc) => AuthUser.fromFirestore(doc));
  }

  Future<void> saveUser(AuthUser user) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }
}
