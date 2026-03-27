import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/di/service_locator.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_user.dart';

class RoleDrawerItem {
  const RoleDrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class RoleDrawerConfig {
  const RoleDrawerConfig({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<RoleDrawerItem> items;
}

class RoleDrawer extends StatelessWidget {
  const RoleDrawer({
    required this.selectedRoute,
    this.overrideTitle,
    this.overrideSubtitle,
    this.overrideItems,
    super.key,
  });

  final String selectedRoute;
  final String? overrideTitle;
  final String? overrideSubtitle;
  final List<RoleDrawerItem>? overrideItems;

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (route == selectedRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final authController = getIt<AuthController>();

    return StreamBuilder<AuthUser?>(
      stream: authController.watchAuthUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final config = _configForRole(user?.role);
        final title = overrideTitle ?? config.title;
        final subtitle = overrideSubtitle ?? config.subtitle;
        final items = overrideItems ?? config.items;

        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF8A7F8F)),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.name.isEmpty ? user.email : user.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user.role.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF6E5B67)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final item in items)
                        ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.label),
                          selected: item.route == selectedRoute,
                          onTap: () => _navigate(context, item.route),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.home_rounded),
                        title: const Text('Home'),
                        selected: selectedRoute == AppRoutes.home,
                        onTap: () => _navigate(context, AppRoutes.home),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.of(context).pop();
                      authController.signOut();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

RoleDrawerConfig _configForRole(AuthRole? role) {
  switch (role) {
    case AuthRole.counter:
      return const RoleDrawerConfig(
        title: 'Counter Workspace',
        subtitle: 'Manage orders and coordinate rider handoffs.',
        items: [
          RoleDrawerItem(
            label: 'Dashboard',
            icon: Icons.point_of_sale_rounded,
            route: AppRoutes.counter,
          ),
          RoleDrawerItem(
            label: 'Orders',
            icon: Icons.receipt_long_rounded,
            route: AppRoutes.orders,
          ),
        ],
      );
    case AuthRole.rider:
      return const RoleDrawerConfig(
        title: 'Rider Workspace',
        subtitle: 'Track your deliveries and update drop-offs.',
        items: [
          RoleDrawerItem(
            label: 'Dashboard',
            icon: Icons.delivery_dining_rounded,
            route: AppRoutes.rider,
          ),
          RoleDrawerItem(
            label: 'Orders',
            icon: Icons.receipt_long_rounded,
            route: AppRoutes.orders,
          ),
        ],
      );
    default:
      return const RoleDrawerConfig(
        title: 'Ayeyo Delivery',
        subtitle: 'Choose a workspace to continue.',
        items: [],
      );
  }
}
