class PlaceOrderItem {
  const PlaceOrderItem({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final int quantity;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'quantity': quantity,
    };
  }
}
