import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/business_settings_repository.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../auth/domain/auth_user.dart';
import '../../menu/domain/meal_session.dart';
import '../../menu/domain/menu_item.dart';
import '../../orders/domain/order_summary.dart';
import '../../orders/domain/order_statuses.dart';
import '../domain/admin_dashboard_state.dart';
import '../domain/admin_metric.dart';
import '../domain/business_settings.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const BusinessSettings _defaultBusinessSettings =
      BusinessSettingsRepository.defaultSettings;

  Future<List<AdminMetric>> loadMetrics() async {
    final settings = await getBusinessSettings();
    return [
      AdminMetric(label: 'Business', value: settings.businessName),
      AdminMetric(label: 'Support phone', value: settings.phone),
      AdminMetric(
        label: 'Default delivery fee',
        value:
            '${settings.currency} ${settings.deliveryFee.toStringAsFixed(0)}',
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

    return _defaultBusinessSettings;
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

      return _defaultBusinessSettings;
    });
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MealSession.fromFirestore).toList()
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
          (snapshot) =>
              snapshot.docs.map(MenuItem.fromFirestore).toList()
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
            final location = data['deliveryLocation'] as Map<String, dynamic>?;
            final latitude = location?['lat'];
            final longitude = location?['lng'];
            final riderLocation = data['riderLocation'] as Map<String, dynamic>?;
            final riderLatitude = riderLocation?['lat'];
            final riderLongitude = riderLocation?['lng'];
            final riderStamp =
                (data['riderLocationUpdatedAt'] as Timestamp?)?.toDate();
            final riderUpdatedAt = riderStamp == null
                ? null
                : '${riderStamp.year}-${riderStamp.month.toString().padLeft(2, '0')}-${riderStamp.day.toString().padLeft(2, '0')} ${riderStamp.hour.toString().padLeft(2, '0')}:${riderStamp.minute.toString().padLeft(2, '0')}';
            return OrderSummary(
              orderId: doc.id,
              orderNumber: '#${doc.id}',
              stage: data['status'] as String? ?? 'pending',
              updatedAt: updatedAt,
              deliveryAddress: data['address'] as String?,
              deliveryLatitude: latitude is num ? latitude.toDouble() : null,
              deliveryLongitude: longitude is num ? longitude.toDouble() : null,
              riderLatitude:
                  riderLatitude is num ? riderLatitude.toDouble() : null,
              riderLongitude:
                  riderLongitude is num ? riderLongitude.toDouble() : null,
              riderLocationUpdatedAt: riderUpdatedAt,
              assignedRiderId: data['assignedRiderId'] as String?,
              assignedRiderName: data['assignedRiderName'] as String?,
              assignedRiderEmail: data['assignedRiderEmail'] as String?,
              trackRiderLocation: data['trackRiderLocation'] as bool? ?? false,
            );
          }).toList(),
        );
  }

  Stream<List<AuthUser>> watchUsers() {
    return _firestore
        .collection(FirestorePaths.users)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AuthUser.fromFirestore).toList()
                ..sort((a, b) {
                  final aLabel = a.name.isEmpty ? a.email : a.name;
                  final bLabel = b.name.isEmpty ? b.email : b.name;
                  return aLabel.toLowerCase().compareTo(bLabel.toLowerCase());
                }),
        );
  }

  Stream<List<AuthUser>> watchRiders() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: AuthRole.rider.key)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AuthUser.fromFirestore).toList()
                ..sort((a, b) {
                  final aLabel = a.name.isEmpty ? a.email : a.name;
                  final bLabel = b.name.isEmpty ? b.email : b.name;
                  return aLabel.toLowerCase().compareTo(bLabel.toLowerCase());
                }),
        );
  }

  Stream<AdminDashboardState> watchDashboard() {
    final controller = StreamController<AdminDashboardState>.broadcast();

    var settings = _defaultBusinessSettings;
    List<MealSession> sessions = const [];
    List<MenuItem> items = const [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> orderDocs = const [];

    void emit() {
      final now = DateTime.now();
      final todayOrdersCount = orderDocs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) {
          return false;
        }

        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      }).length;

      final pendingOrdersCount = orderDocs.where((doc) {
        return (doc.data()['status'] as String? ?? OrderStatuses.pending) ==
            OrderStatuses.pending;
      }).length;

      final activeSession = _findActiveSession(sessions, now: now);
      final soldOutItemsCount = items.where((item) {
        return !item.isAvailable || item.stock <= 0;
      }).length;

      controller.add(
        AdminDashboardState(
          todaysOrdersCount: todayOrdersCount,
          pendingOrdersCount: pendingOrdersCount,
          activeMealSessionName: activeSession?.name ?? 'No active session',
          soldOutItemsCount: soldOutItemsCount,
          businessName: settings.businessName,
          bannerMessage: settings.bannerMessage,
          activeOffer: settings.activeOffer,
          pickupEnabled: settings.pickupEnabled,
          orderingOpen: settings.orderingOpen,
        ),
      );
    }

    final settingsSub = watchBusinessSettings().listen((value) {
      settings = value;
      emit();
    });

    final sessionsSub = watchMealSessions().listen((value) {
      sessions = value;
      emit();
    });

    final itemsSub = watchMenuItems().listen((value) {
      items = value;
      emit();
    });

    final ordersSub = _firestore
        .collection(FirestorePaths.orders)
        .snapshots()
        .listen((value) {
          orderDocs = value.docs;
          emit();
        });

    emit();

    controller.onCancel = () async {
      await settingsSub.cancel();
      await sessionsSub.cancel();
      await itemsSub.cancel();
      await ordersSub.cancel();
    };

    return controller.stream;
  }

  MealSession? _findActiveSession(List<MealSession> sessions, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final currentMinutes = (currentTime.hour * 60) + currentTime.minute;

    for (final session in sessions) {
      if (!session.isActive) {
        continue;
      }

      final start = (session.startHour * 60) + session.startMinute;
      final end = (session.endHour * 60) + session.endMinute;
      if (currentMinutes >= start && currentMinutes <= end) {
        return session;
      }
    }

    return null;
  }

  Future<void> saveMealSession(MealSession session) {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .doc(session.id)
        .set(session.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMealSession(String sessionId) {
    return _firestore
        .collection(FirestorePaths.mealSessions)
        .doc(sessionId)
        .delete();
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

  Future<void> assignOrderToRider({
    required String orderId,
    required AuthUser rider,
  }) {
    return _firestore.collection(FirestorePaths.orders).doc(orderId).update({
      'assignedRiderId': rider.id,
      'assignedRiderName': rider.name,
      'assignedRiderEmail': rider.email,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderTracking({
    required String orderId,
    required bool enabled,
  }) {
    return _firestore.collection(FirestorePaths.orders).doc(orderId).update({
      'trackRiderLocation': enabled,
      'trackRiderLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRole(String userId, AuthRole role) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .set({'role': role.key}, SetOptions(merge: true));
  }
}
