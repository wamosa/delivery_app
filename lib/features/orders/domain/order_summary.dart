class OrderSummary {
  const OrderSummary({
    required this.orderNumber,
    required this.stage,
    required this.updatedAt,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.assignedRiderId,
    this.assignedRiderName,
    this.assignedRiderEmail,
  });

  final String orderNumber;
  final String stage;
  final String updatedAt;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final String? assignedRiderEmail;
}
