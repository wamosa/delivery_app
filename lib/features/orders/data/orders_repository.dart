import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/order_summary.dart';

class OrdersRepository {
  OrdersRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<List<OrderSummary>> loadOrders() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const [];
    }

    final snapshot = await _firestore
        .collection(FirestorePaths.orders)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return _toSummary(doc.data(), doc.id);
    }).toList();
  }

  Stream<List<OrderSummary>> watchOrders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection(FirestorePaths.orders)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _toSummary(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<OrderSummary>> watchAssignedOrders() {
    final riderId = _auth.currentUser?.uid;
    if (riderId == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection(FirestorePaths.orders)
        .where('assignedRiderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _toSummary(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<OrderSummary>> watchAdminOrders() {
    return _firestore
        .collection(FirestorePaths.orders)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _toSummary(doc.data(), doc.id))
              .toList(),
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

  Future<void> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) {
    return _firestore.collection(FirestorePaths.orders).doc(orderId).update({
      'riderLocation': {'lat': latitude, 'lng': longitude},
      'riderLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  OrderSummary _toSummary(Map<String, dynamic> data, String id) {
    final stamp =
        ((data['updatedAt'] ?? data['createdAt']) as Timestamp?)?.toDate();
    final updatedLabel = stamp == null
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
    final riderUpdatedLabel = riderStamp == null
        ? null
        : '${riderStamp.year}-${riderStamp.month.toString().padLeft(2, '0')}-${riderStamp.day.toString().padLeft(2, '0')} ${riderStamp.hour.toString().padLeft(2, '0')}:${riderStamp.minute.toString().padLeft(2, '0')}';
    return OrderSummary(
      orderId: id,
      orderNumber: '#$id',
      stage: data['status'] as String? ?? 'pending',
      updatedAt: updatedLabel,
      deliveryAddress: data['address'] as String?,
      deliveryLatitude: latitude is num ? latitude.toDouble() : null,
      deliveryLongitude: longitude is num ? longitude.toDouble() : null,
      riderLatitude: riderLatitude is num ? riderLatitude.toDouble() : null,
      riderLongitude: riderLongitude is num ? riderLongitude.toDouble() : null,
      riderLocationUpdatedAt: riderUpdatedLabel,
      assignedRiderId: data['assignedRiderId'] as String?,
      assignedRiderName: data['assignedRiderName'] as String?,
      assignedRiderEmail: data['assignedRiderEmail'] as String?,
      trackRiderLocation: data['trackRiderLocation'] as bool? ?? false,
    );
  }
}
