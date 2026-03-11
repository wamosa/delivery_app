import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../menu/domain/meal_session.dart';
import '../../menu/domain/menu_item.dart';
import '../../orders/domain/order_summary.dart';
import '../domain/admin_metric.dart';
import '../domain/business_settings.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AdminMetric>> loadMetrics() async {
    final settings = await getBusinessSettings();
    return [
      AdminMetric(label: 'Business', value: settings.businessName),
      AdminMetric(label: 'Support phone', value: settings.phone),
      AdminMetric(
        label: 'Default delivery fee',
        value: '${settings.currency} ${settings.deliveryFee.toStringAsFixed(0)}',
      ),
      AdminMetric(
        label: 'Ordering',
        value: settings.orderingOpen ? 'Open' : 'Closed',
      ),
    ];
  }

  Future<BusinessSettings> getBusinessSettings() async {
    final doc = await _firestore.doc(FirestorePaths.businessSettings).get();

    if (doc.exists) {
      return BusinessSettings.fromFirestore(doc);
    }

    return const BusinessSettings(
      businessName: 'Ayeyo Delivery',
      phone: '+254700111222',
      deliveryFee: 180,
      taxRate: 0,
      currency: 'KSh',
      pickupEnabled: true,
      orderingOpen: true,
      openingHoursNote: 'Breakfast 9:00-11:00, lunch 12:00-15:00',
      bannerMessage: 'Fresh meals for every session',
      activeOffer: 'Free juice on lunch combo orders',
    );
  }

  Future<void> saveBusinessSettings(BusinessSettings settings) {
    return _firestore
        .doc(FirestorePaths.businessSettings)
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<BusinessSettings> watchBusinessSettings() {
    return _firestore.doc(FirestorePaths.businessSettings).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return BusinessSettings.fromFirestore(doc);
      }

      return const BusinessSettings(
        businessName: 'Ayeyo Delivery',
        phone: '+254700111222',
        deliveryFee: 180,
        taxRate: 0,
        currency: 'KSh',
        pickupEnabled: true,
        orderingOpen: true,
        openingHoursNote: 'Breakfast 9:00-11:00, lunch 12:00-15:00',
        bannerMessage: 'Fresh meals for every session',
        activeOffer: 'Free juice on lunch combo orders',
      );
    });
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

  Stream<List<MenuItem>> watchMenuItems() {
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

  Stream<List<OrderSummary>> watchOrders() {
    return _firestore
        .collection(FirestorePaths.orders)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final stamp =
                ((data['updatedAt'] ?? data['createdAt']) as Timestamp?)
                    ?.toDate();
            final updatedAt = stamp == null
                ? 'Awaiting update'
                : '${stamp.year}-${stamp.month.toString().padLeft(2, '0')}-${stamp.day.toString().padLeft(2, '0')} ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';
            return OrderSummary(
              orderNumber: '#${doc.id}',
              stage: data['status'] as String? ?? 'pending',
              updatedAt: updatedAt,
            );
          }).toList(),
        );
  }

  Future<void> saveMealSession(MealSession session) {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .doc(session.id)
        .set(session.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMealSession(String sessionId) {
    return _firestore.collection(FirestorePaths.mealSessions).doc(sessionId).delete();
  }

  Future<void> saveMenuItem(MenuItem item) {
    return _firestore
        .collection(FirestorePaths.menuItems)
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMenuItem(String itemId) {
    return _firestore.collection(FirestorePaths.menuItems).doc(itemId).delete();
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore.collection(FirestorePaths.orders).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
