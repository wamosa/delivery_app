import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/orders/presentation/orders_page.dart';
import 'app_routes.dart';

class AyeyoApp extends StatelessWidget {
  const AyeyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayeyo Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.auth: (_) => const AuthPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.menu: (_) => const MenuPage(),
        AppRoutes.cart: (_) => const CartPage(),
        AppRoutes.checkout: (_) => const CheckoutPage(),
        AppRoutes.orders: (_) => const OrdersPage(),
        AppRoutes.admin: (_) => const AdminPage(),
      },
    );
  }
}
