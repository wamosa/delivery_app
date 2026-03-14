import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/meal_session.dart';
import '../domain/menu_item.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  List<MealSession> _resolveMealSessions(List<MealSession> sessions) {
    return List<MealSession>.from(sessions)..sort((a, b) {
      final aMinutes = (a.startHour * 60) + a.startMinute;
      final bMinutes = (b.startHour * 60) + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  List<MenuItem> _sortItems(List<MenuItem> items) {
    return List<MenuItem>.from(items)..sort((a, b) => a.name.compareTo(b.name));
  }

  List<MenuItem> _resolveAvailableItems(List<MenuItem> items) {
    return _sortItems(
      items.where((item) => item.isAvailable && item.stock > 0).toList(),
    );
  }

  List<MenuItem> _resolveAvailableItemsForSession(
    String sessionId,
    List<MenuItem> items,
  ) {
    return _sortItems(
      items
          .where(
            (item) =>
                item.isAvailable &&
                item.stock > 0 &&
                item.mealSessionId == sessionId,
          )
          .toList(),
    );
  }

  List<MenuItem> _resolveAllItems(List<MenuItem> items) {
    return _sortItems(items);
  }

  Future<List<MenuItem>> fetchPopularItems() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.menuItems)
        .where('isAvailable', isEqualTo: true)
        .orderBy('name')
        .get();

    return _resolveAvailableItems(
      snapshot.docs.map(MenuItem.fromFirestore).toList(),
    );
  }

  Stream<List<MenuItem>> watchAvailableItems() {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return _resolveAvailableItems(
            snapshot.docs.map(MenuItem.fromFirestore).toList(),
          );
        });
  }

  Stream<List<MenuItem>> watchAvailableItemsForSession(String sessionId) {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .where('isAvailable', isEqualTo: true)
        .where('mealSessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
          return _resolveAvailableItemsForSession(
            sessionId,
            snapshot.docs.map(MenuItem.fromFirestore).toList(),
          );
        });
  }

  Stream<List<MenuItem>> watchAllItems() {
    return _firestore.collection(FirestorePaths.menuItems).snapshots().map((
      snapshot,
    ) {
      return _resolveAllItems(
        snapshot.docs.map(MenuItem.fromFirestore).toList(),
      );
    });
  }

  Future<List<MealSession>> fetchMealSessions() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.mealSessions)
        .orderBy('startHour')
        .orderBy('startMinute')
        .get();
    return _resolveMealSessions(
      snapshot.docs.map(MealSession.fromFirestore).toList(),
    );
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _firestore.collection(FirestorePaths.mealSessions).snapshots().map((
      snapshot,
    ) {
      return _resolveMealSessions(
        snapshot.docs.map(MealSession.fromFirestore).toList(),
      );
    });
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
