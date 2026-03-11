class OrderStatuses {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const outForDelivery = 'out_for_delivery';
  static const completed = 'completed';
  static const canceled = 'canceled';

  static const values = [
    pending,
    accepted,
    preparing,
    ready,
    outForDelivery,
    completed,
    canceled,
  ];
}
