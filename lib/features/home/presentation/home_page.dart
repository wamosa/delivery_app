import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    if (user.role == AuthRole.admin) {
      return const _AdminHomePage();
    }

    final modules = getIt<HomeController>().loadModules(user.role);

    return FeatureScaffold(
      title: 'Ayeyo Delivery',
      subtitle: 'Choose a workspace to continue with your role-specific tools.',
      children: [
        ...modules.map(
          (module) => InfoCard(
            title: module.title,
            description: module.description,
            trailing: FilledButton(
              onPressed: () => Navigator.pushNamed(context, module.route),
              child: const Text('Open'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminHomePage extends StatelessWidget {
  const _AdminHomePage();

  @override
  Widget build(BuildContext context) {
    final authController = getIt<AuthController>();
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width < 360
        ? 16.0
        : width < Breakpoints.compact
        ? 20.0
        : 32.0;
    final maxContentWidth = width < Breakpoints.wide ? double.infinity : 720.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: authController.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AdminHomeCard(
                      title: 'Admin tools',
                      description:
                          'Open the main admin dashboard to manage menu items, meal sessions, settings, and business activity.',
                      icon: Icons.dashboard_customize_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminPage(initialIndex: 0),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AdminHomeCard(
                      title: 'Order operations',
                      description:
                          'Jump straight into the admin orders workspace to review and update incoming orders.',
                      icon: Icons.receipt_long_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminPage(initialIndex: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AdminHomeCard(
                      title: 'Rider workspace',
                      description:
                          'Open the rider experience to view assigned deliveries and update statuses.',
                      icon: Icons.delivery_dining_rounded,
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.rider);
                      },
                    ),
                    const SizedBox(height: 20),
                    _RoleSwitcherCard(
                      onOpenRole: (route) {
                        Navigator.of(context).pushNamed(route);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitcherCard extends StatelessWidget {
  const _RoleSwitcherCard({required this.onOpenRole});

  final ValueChanged<String> onOpenRole;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview other roles',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Quickly jump into other role experiences without changing your account.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onOpenRole(AppRoutes.rider),
                  icon: const Icon(Icons.delivery_dining_rounded),
                  label: const Text('Rider view'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenRole(AppRoutes.counter),
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('Counter view'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenRole(AppRoutes.menu),
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: const Text('Customer view'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeCard extends StatelessWidget {
  const _AdminHomeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD6E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2B2130),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6E5B67),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
