import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/meal_session.dart';
import '../domain/menu_item.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<MealSession> _dummyMealSessions = [
    MealSession(
      id: 'breakfast',
      name: 'Breakfast',
      startHour: 9,
      startMinute: 0,
      endHour: 11,
      endMinute: 0,
      isActive: true,
    ),
    MealSession(
      id: 'lunch',
      name: 'Lunch',
      startHour: 12,
      startMinute: 0,
      endHour: 15,
      endMinute: 0,
      isActive: true,
    ),
    MealSession(
      id: 'snacks',
      name: 'Snacks & More',
      startHour: 16,
      startMinute: 0,
      endHour: 23,
      endMinute: 0,
      isActive: true,
    ),
  ];

  static const List<MenuItem> _dummyMenuItems = [
    MenuItem(
      id: 'breakfast-tea-samosa',
      name: 'Tea & Samosa',
      description: 'Hot chai served with a fresh samosa.',
      price: 120,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/breakfast_tea_samosa.png',
      categoryName: 'Breakfast',
      mealSessionId: 'breakfast',
      isAvailable: true,
      stock: 20,
      prepTimeMinutes: 15,
    ),
    MenuItem(
      id: 'breakfast-mandazi',
      name: 'Mandazi Combo',
      description: 'Soft mandazi with spiced tea for a light breakfast.',
      price: 180,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/breakfast_mandazi.png',
      categoryName: 'Breakfast',
      mealSessionId: 'breakfast',
      isAvailable: true,
      stock: 16,
      prepTimeMinutes: 10,
    ),
    MenuItem(
      id: 'lunch-pilau-beef',
      name: 'Pilau Beef',
      description: 'Spiced pilau rice served with rich beef stew.',
      price: 350,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/lunch_pilau_beef.png',
      categoryName: 'Lunch',
      mealSessionId: 'lunch',
      isAvailable: true,
      stock: 15,
      prepTimeMinutes: 25,
    ),
    MenuItem(
      id: 'lunch-chicken-stew',
      name: 'Ugali & Chicken Stew',
      description: 'Ugali plated with tender chicken stew and greens.',
      price: 420,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/lunch_chicken_stew.png',
      categoryName: 'Lunch',
      mealSessionId: 'lunch',
      isAvailable: true,
      stock: 12,
      prepTimeMinutes: 30,
    ),
    MenuItem(
      id: 'snacks-chips-sausage',
      name: 'Chips & Sausage',
      description: 'Crispy fries served with a grilled sausage.',
      price: 250,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/snacks_chips_sausage.png',
      categoryName: 'Snacks',
      mealSessionId: 'snacks',
      isAvailable: true,
      stock: 18,
      prepTimeMinutes: 20,
    ),
    MenuItem(
      id: 'snacks-bhajia',
      name: 'Bhajia Basket',
      description: 'Golden potato bhajias with tangy house dip.',
      price: 220,
      imageUrl: '',
      localImageAsset: 'assets/images/menu/snacks_bhajia.png',
      categoryName: 'Snacks',
      mealSessionId: 'snacks',
      isAvailable: true,
      stock: 14,
      prepTimeMinutes: 18,
    ),
  ];

  List<MealSession> _resolveMealSessions(List<MealSession> sessions) {
    final resolved = sessions.isEmpty ? _dummyMealSessions : sessions;
    return List<MealSession>.from(resolved)..sort((a, b) {
      final aMinutes = (a.startHour * 60) + a.startMinute;
      final bMinutes = (b.startHour * 60) + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  List<MenuItem> _sortItems(List<MenuItem> items) {
    return List<MenuItem>.from(items)..sort((a, b) => a.name.compareTo(b.name));
  }

  List<MenuItem> _resolveAvailableItems(List<MenuItem> items) {
    final availableItems = items.where((item) => item.isAvailable).toList();
    if (availableItems.isNotEmpty) {
      return _sortItems(availableItems);
    }

    return _sortItems(
      _dummyMenuItems.where((item) => item.isAvailable).toList(),
    );
  }

  List<MenuItem> _resolveAvailableItemsForSession(
    String sessionId,
    List<MenuItem> items,
  ) {
    final sessionItems = items
        .where((item) => item.isAvailable && item.mealSessionId == sessionId)
        .toList();
    if (sessionItems.isNotEmpty) {
      return _sortItems(sessionItems);
    }

    return _sortItems(
      _dummyMenuItems
          .where((item) => item.isAvailable && item.mealSessionId == sessionId)
          .toList(),
    );
  }

  List<MenuItem> _resolveAllItems(List<MenuItem> items) {
    if (items.isNotEmpty) {
      return _sortItems(items);
    }

    return _sortItems(_dummyMenuItems);
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
