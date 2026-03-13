import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_user.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/role_gate.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/counter/presentation/counter_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/rider/presentation/rider_page.dart';
import 'app_routes.dart';

class AyeyoApp extends StatelessWidget {
  const AyeyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return MaterialApp(
      title: 'Ayeyo Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: StreamBuilder<AuthUser?>(
        stream: authController.watchAuthUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const AuthPage();
          }

          return _RoleBasedHome(user: user);
        },
      ),
      routes: {
        AppRoutes.auth: (_) => const AuthPage(),
        AppRoutes.menu: (_) => const RoleGate(
              allowedRoles: [AuthRole.customer],
              child: MenuPage(),
            ),
        AppRoutes.cart: (_) => const RoleGate(
              allowedRoles: [AuthRole.customer],
              child: CartPage(),
            ),
        AppRoutes.checkout: (_) => const RoleGate(
              allowedRoles: [AuthRole.customer],
              child: CheckoutPage(),
            ),
        AppRoutes.orders: (_) => const RoleGate(
              allowedRoles: [
                AuthRole.customer,
                AuthRole.admin,
                AuthRole.counter,
                AuthRole.rider,
              ],
              child: OrdersPage(),
            ),
        AppRoutes.admin: (_) => const RoleGate(
              allowedRoles: [AuthRole.admin],
              child: AdminPage(),
            ),
        AppRoutes.counter: (_) => const RoleGate(
              allowedRoles: [AuthRole.admin, AuthRole.counter],
              child: CounterPage(),
            ),
        AppRoutes.rider: (_) => const RoleGate(
              allowedRoles: [AuthRole.admin, AuthRole.rider],
              child: RiderPage(),
            ),
      },
    );
  }
}

class _RoleBasedHome extends StatelessWidget {
  const _RoleBasedHome({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case AuthRole.admin:
      case AuthRole.counter:
      case AuthRole.rider:
        return HomePage(user: user);
      case AuthRole.customer:
        return const MenuPage();
    }
  }
}
