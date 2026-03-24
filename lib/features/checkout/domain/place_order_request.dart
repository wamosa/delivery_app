import 'place_order_item.dart';

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.items,
    required this.deliveryType,
    required this.address,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  final List<PlaceOrderItem> items;
  final String deliveryType;
  final String address;
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
      if (deliveryLocation != null) 'deliveryLocation': deliveryLocation,
    };
  }
}
