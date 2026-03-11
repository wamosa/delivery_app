import 'place_order_item.dart';

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.items,
    required this.deliveryType,
    required this.address,
  });

  final List<PlaceOrderItem> items;
  final String deliveryType;
  final String address;

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'deliveryType': deliveryType,
      'address': address,
    };
  }
}
