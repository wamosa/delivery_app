import '../data/orders_repository.dart';
import '../../auth/domain/auth_user.dart';
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

  Stream<List<AuthUser>> watchRiders() {
    return _repository.watchRiders();
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _repository.updateOrderStatus(orderId, status);
  }

  Future<void> assignOrderToRider({
    required String orderId,
    required AuthUser rider,
  }) {
    return _repository.assignOrderToRider(orderId: orderId, rider: rider);
  }

  Future<void> requestOrderAssignment({
    required String orderId,
    required AuthUser rider,
  }) {
    return _repository.requestOrderAssignment(orderId: orderId, rider: rider);
  }

  Future<void> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) {
    return _repository.updateRiderLocation(
      orderId: orderId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
