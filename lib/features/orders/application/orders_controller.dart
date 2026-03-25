import '../data/orders_repository.dart';
import '../domain/order_summary.dart';

class OrdersController {
  OrdersController({OrdersRepository? repository})
      : _repository = repository ?? OrdersRepository();

  final OrdersRepository _repository;

  Future<List<OrderSummary>> loadOrders() {
    return _repository.loadOrders();
  }

  Stream<List<OrderSummary>> watchOrders() {
    return _repository.watchOrders();
  }

  Stream<List<OrderSummary>> watchAssignedOrders() {
    return _repository.watchAssignedOrders();
  }

  Stream<List<OrderSummary>> watchAdminOrders() {
    return _repository.watchAdminOrders();
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _repository.updateOrderStatus(orderId, status);
  }
}
