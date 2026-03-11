import '../../../app/app_routes.dart';
import '../domain/dashboard_item.dart';

class HomeRepository {
  List<DashboardItem> loadModules() {
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
      DashboardItem(
        title: 'Admin tools',
        description: 'Merchant onboarding, dispatch oversight, and analytics.',
        route: AppRoutes.admin,
      ),
      DashboardItem(
        title: 'Auth area',
        description: 'Sign in, account profile, and role-based access.',
        route: AppRoutes.auth,
      ),
    ];
  }
}
