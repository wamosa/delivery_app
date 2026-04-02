import 'place_order_item.dart';

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.items,
    required this.deliveryType,
    required this.address,
    required this.paymentMethod,
    this.paymentPhone,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  final List<PlaceOrderItem> items;
  final String deliveryType;
  final String address;
  final String paymentMethod;
  final String? paymentPhone;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  Map<String, dynamic> toMap() {
    final deliveryLocation =
        deliveryLatitude == null || deliveryLongitude == null
            ? null
            : {
              'lat': deliveryLatitude,
              'lng': deliveryLongitude,
            };
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'deliveryType': deliveryType,
      'address': address,
      'paymentMethod': paymentMethod,
      if (paymentPhone != null && paymentPhone!.isNotEmpty)
        'paymentPhone': paymentPhone,
      if (deliveryLocation != null) 'deliveryLocation': deliveryLocation,
    };
  }
}
