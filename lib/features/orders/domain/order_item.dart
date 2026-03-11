class OrderItem {
  const OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
