class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.orderNumber,
    required this.stage,
    required this.updatedAt,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.riderLatitude,
    this.riderLongitude,
    this.riderLocationUpdatedAt,
    this.assignedRiderId,
    this.assignedRiderName,
    this.assignedRiderEmail,
    this.trackRiderLocation = false,
  });

  final String orderId;
  final String orderNumber;
  final String stage;
  final String updatedAt;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? riderLatitude;
  final double? riderLongitude;
  final String? riderLocationUpdatedAt;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final String? assignedRiderEmail;
  final bool trackRiderLocation;
}
