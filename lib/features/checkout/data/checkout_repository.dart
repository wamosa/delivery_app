import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/data/business_settings_repository.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../domain/checkout_preview.dart';
import '../domain/place_order_request.dart';
import '../domain/place_order_result.dart';

class CheckoutRepository {
  CheckoutRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    BusinessSettingsRepository? businessSettingsRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _businessSettingsRepository =
            businessSettingsRepository ?? BusinessSettingsRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final BusinessSettingsRepository _businessSettingsRepository;

  CheckoutPreview getPreview() {
    return const CheckoutPreview(
      address: 'Westlands, Nairobi',
      paymentMethod: 'M-Pesa',
      eta: '25-35 min',
    );
  }

  Future<PlaceOrderResult> placeOrder(PlaceOrderRequest request) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to place an order.');
    }

    if (request.items.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    final settings = await _businessSettingsRepository.getBusinessSettings();
    final double deliveryFee =
        request.deliveryType == 'pickup' ? 0.0 : settings.deliveryFee;

    final quantityById = <String, int>{};
    for (final item in request.items) {
      quantityById[item.itemId] =
          (quantityById[item.itemId] ?? 0) + item.quantity;
    }

    final menuRefs = quantityById.keys
        .map(
          (itemId) => _firestore.collection(FirestorePaths.menuItems).doc(itemId),
        )
        .toList();

    return _firestore.runTransaction((transaction) async {
      final menuDataById = <String, Map<String, dynamic>>{};

      for (final ref in menuRefs) {
        final snap = await transaction.get(ref);
        if (!snap.exists) {
          throw StateError('Menu item ${ref.id} was not found.');
        }
        final data = snap.data() ?? <String, dynamic>{};
        final available = data['isAvailable'] as bool? ?? false;
        if (!available) {
          throw StateError('${data['name'] ?? 'Item'} is sold out.');
        }
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final requestedQty = quantityById[ref.id] ?? 0;
        if (stock < requestedQty) {
          throw StateError('${data['name'] ?? 'Item'} is sold out.');
        }
        menuDataById[ref.id] = data;

        transaction.update(ref, {
          'stock': stock - requestedQty,
        });
      }

      double subtotal = 0;
      final orderItems = <Map<String, dynamic>>[];
      String? mealSessionId;

      for (final itemRequest in request.items) {
        final data = menuDataById[itemRequest.itemId] ?? <String, dynamic>{};
        final unitPrice = (data['price'] as num?)?.toDouble() ?? 0;
        final name = data['name'] as String? ?? 'Item';
        final itemMealSessionId = data['mealSessionId'] as String?;
        mealSessionId ??= itemMealSessionId;

        subtotal += unitPrice * itemRequest.quantity;
        orderItems.add({
          'itemId': itemRequest.itemId,
          'name': name,
          'quantity': itemRequest.quantity,
          'unitPrice': unitPrice,
        });
      }

      final total = subtotal + deliveryFee;
      final orderRef = _firestore.collection(FirestorePaths.orders).doc();

      transaction.set(orderRef, {
        'userId': userId,
        'items': orderItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': 'pending',
        if (mealSessionId != null) 'mealSessionId': mealSessionId,
        'deliveryType': request.deliveryType,
        'address': request.address,
        'deliveryLocation': request.deliveryLatitude == null ||
                request.deliveryLongitude == null
            ? null
            : {
              'lat': request.deliveryLatitude,
              'lng': request.deliveryLongitude,
            },
        'createdAt': FieldValue.serverTimestamp(),
      });

      return PlaceOrderResult(
        orderId: orderRef.id,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: 'pending',
      );
    });
  }
}
