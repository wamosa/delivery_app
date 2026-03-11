class PlaceOrderResult {
  const PlaceOrderResult({
    required this.orderId,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
  });

  final String orderId;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;

  factory PlaceOrderResult.fromMap(Map<Object?, Object?> map) {
    return PlaceOrderResult(
      orderId: map['orderId'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? '',
    );
  }
}
