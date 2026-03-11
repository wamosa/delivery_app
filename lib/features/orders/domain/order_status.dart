class OrderStatus {
  const OrderStatus({
    required this.orderNumber,
    required this.stage,
    required this.updatedAt,
  });

  final String orderNumber;
  final String stage;
  final String updatedAt;
}
