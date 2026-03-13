import '../../../app/app_routes.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/dashboard_item.dart';

class HomeRepository {
  List<DashboardItem> loadModules(AuthRole role) {
    switch (role) {
      case AuthRole.admin:
        return const [
          DashboardItem(
            title: 'Admin tools',
            description:
                'Manage staff, settings, analytics, and overall operations.',
            route: AppRoutes.admin,
          ),
          DashboardItem(
            title: 'Order operations',
            description: 'Monitor incoming, active, and completed orders.',
            route: AppRoutes.orders,
          ),
        ];
      case AuthRole.counter:
        return const [
          DashboardItem(
            title: 'Counter dashboard',
            description: 'Receive, confirm, pack, and roll out customer orders.',
            route: AppRoutes.counter,
          ),
          DashboardItem(
            title: 'Kitchen queue',
            description: 'Track active orders and prep progress.',
            route: AppRoutes.orders,
          ),
        ];
      case AuthRole.rider:
        return const [
          DashboardItem(
            title: 'Delivery dashboard',
            description: 'Pick up assigned food orders and update delivery status.',
            route: AppRoutes.rider,
          ),
          DashboardItem(
            title: 'Assigned orders',
            description: 'View pickup details and current delivery jobs.',
            route: AppRoutes.orders,
          ),
        ];
      case AuthRole.customer:
        return const [
          DashboardItem(
            title: 'Browse restaurants',
            description: 'Menu discovery, categories, and store details.',
            route: AppRoutes.menu,
          ),
          DashboardItem(
            title: 'View cart',
            description: 'Selected items, pricing, delivery fees, and totals.',
            route: AppRoutes.cart,
          ),
          DashboardItem(
            title: 'Checkout',
            description: 'Address, payment, rider instructions, and confirmation.',
            route: AppRoutes.checkout,
          ),
          DashboardItem(
            title: 'Track orders',
            description: 'Current delivery status and order history.',
            route: AppRoutes.orders,
          ),
        ];
    }
  }
}
