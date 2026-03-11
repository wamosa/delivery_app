class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double total;

  String get subtotalLabel => 'KSh ${subtotal.toStringAsFixed(0)}';

  String get deliveryFeeLabel => 'KSh ${deliveryFee.toStringAsFixed(0)}';

  String get totalLabel => 'KSh ${total.toStringAsFixed(0)}';
}
