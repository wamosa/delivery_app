import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firestore_paths.dart';
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

  Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore.collection(FirestorePaths.orders).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  OrderSummary _toSummary(Map<String, dynamic> data, String id) {
    final stamp =
        ((data['updatedAt'] ?? data['createdAt']) as Timestamp?)?.toDate();
    final updatedLabel = stamp == null
        ? 'Awaiting update'
        : '${stamp.year}-${stamp.month.toString().padLeft(2, '0')}-${stamp.day.toString().padLeft(2, '0')} ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';
    return OrderSummary(
      orderNumber: '#$id',
      stage: data['status'] as String? ?? 'pending',
      updatedAt: updatedLabel,
    );
  }
}
