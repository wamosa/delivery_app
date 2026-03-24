import '../data/admin_repository.dart';
import '../domain/admin_dashboard_state.dart';
import '../domain/admin_metric.dart';
import '../domain/business_settings.dart';
import '../../auth/domain/auth_user.dart';
import '../../menu/domain/meal_session.dart';
import '../../menu/domain/menu_item.dart';
import '../../orders/domain/order_summary.dart';

class AdminController {
  AdminController({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  Future<List<AdminMetric>> loadMetrics() {
    return _repository.loadMetrics();
  }

  Stream<AdminDashboardState> watchDashboard() {
    return _repository.watchDashboard();
  }

  Future<BusinessSettings> loadBusinessSettings() {
    return _repository.getBusinessSettings();
  }

  Stream<BusinessSettings> watchBusinessSettings() {
    return _repository.watchBusinessSettings();
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _repository.watchMealSessions();
  }

  Stream<List<MenuItem>> watchMenuItems() {
    return _repository.watchMenuItems();
  }

  Stream<List<OrderSummary>> watchOrders() {
    return _repository.watchOrders();
  }

  Stream<List<AuthUser>> watchUsers() {
    return _repository.watchUsers();
  }

  Stream<List<AuthUser>> watchRiders() {
    return _repository.watchRiders();
  }

  Future<void> saveBusinessSettings(BusinessSettings settings) {
    return _repository.saveBusinessSettings(settings);
  }

  Future<void> saveMealSession(MealSession session) {
    return _repository.saveMealSession(session);
  }

  Future<void> deleteMealSession(String sessionId) {
    return _repository.deleteMealSession(sessionId);
  }

  Future<void> saveMenuItem(MenuItem item) {
    return _repository.saveMenuItem(item);
  }

  Future<void> deleteMenuItem(String itemId) {
    return _repository.deleteMenuItem(itemId);
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

  Future<void> updateUserRole(String userId, AuthRole role) {
    return _repository.updateUserRole(userId, role);
  }
}
