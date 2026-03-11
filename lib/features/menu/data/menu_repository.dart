import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/meal_session.dart';
import '../domain/menu_item.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<MenuItem>> fetchPopularItems() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.menuItems)
        .where('isAvailable', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs.map(MenuItem.fromFirestore).toList();
  }

  Stream<List<MenuItem>> watchAvailableItems() {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MenuItem.fromFirestore)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Stream<List<MenuItem>> watchAllItems() {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MenuItem.fromFirestore)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<List<MealSession>> fetchMealSessions() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.mealSessions)
        .orderBy('startHour')
        .orderBy('startMinute')
        .get();
    return snapshot.docs.map(MealSession.fromFirestore).toList();
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MealSession.fromFirestore)
              .toList()
            ..sort((a, b) {
              final aMinutes = (a.startHour * 60) + a.startMinute;
              final bMinutes = (b.startHour * 60) + b.startMinute;
              return aMinutes.compareTo(bMinutes);
            }),
        );
  }

  Future<void> saveMenuItem(MenuItem item) {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> saveMealSession(MealSession session) {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .doc(session.id)
        .set(session.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMenuItem(String id) {
    return _firestore.collection(FirestorePaths.menuItems).doc(id).delete();
  }

  Future<void> deleteMealSession(String id) {
    return _firestore.collection(FirestorePaths.mealSessions).doc(id).delete();
  }
}
