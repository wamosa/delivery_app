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

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Stream<AuthUser?> watchAuthUser() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<AuthUser?>.value(null);
      }

      final userRef =
          _firestore.collection(FirestorePaths.users).doc(firebaseUser.uid);

      return userRef.snapshots().asyncMap(
        (doc) => _createOrLoadUserProfile(
          firebaseUser,
          document: doc,
        ),
      );
    });
  }

  Future<AuthUser> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('No signed-in Firebase user was found.');
    }

    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(firebaseUser.uid)
        .get();

    return _createOrLoadUserProfile(firebaseUser, document: doc);
  }

  Stream<AuthUser> watchCurrentUser() async* {
    await for (final user in watchAuthUser()) {
      if (user != null) {
        yield user;
      }
    }
  }

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return getCurrentUser();
  }

  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a signed-in user.');
    }

    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }

    final authUser = AuthUser(
      id: user.uid,
      name: name.trim().isEmpty ? 'Ayeyo Customer' : name.trim(),
      phone: user.phoneNumber ?? '',
      email: user.email ?? email,
      role: AuthRole.customer,
    );

    await saveUser(authUser);
    return authUser;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> saveUser(AuthUser user) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<AuthUser> _createOrLoadUserProfile(
    User firebaseUser, {
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final existingDocument = document ??
        await _firestore
            .collection(FirestorePaths.users)
            .doc(firebaseUser.uid)
            .get();

    if (existingDocument.exists) {
      return AuthUser.fromFirestore(existingDocument);
    }

    final fallbackUser = AuthUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Ayeyo Customer',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email ?? '',
      role: AuthRole.customer,
    );

    await saveUser(fallbackUser);
    return fallbackUser;
  }
}
