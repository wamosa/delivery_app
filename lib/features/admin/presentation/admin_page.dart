import 'package:flutter/material.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/di/service_locator.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../menu/domain/meal_session.dart';
import '../../menu/domain/menu_item.dart';
import '../../orders/domain/order_statuses.dart';
import '../../orders/domain/order_summary.dart';
import '../application/admin_controller.dart';
import '../domain/admin_dashboard_state.dart';
import '../domain/business_settings.dart';
import '../../auth/presentation/auth_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final authController = getIt<AuthController>();

    return StreamBuilder<AuthUser?>(
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

        if (user.role != AuthRole.admin) {
          return FeatureScaffold(
            title: 'Admin access required',
            subtitle:
                'This area is reserved for accounts with the admin role only.',
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('You are signed in without admin rights'),
                  subtitle: Text(
                    'Signed in as ${user.email}. Ask an existing admin to grant admin access and then sign out and back in to refresh your role.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: authController.signOut,
                  child: const Text('Sign out'),
                ),
              ),
            ],
          );
        }

        return _AdminShell(user: user, initialIndex: initialIndex);
      },
    );
  }
}

class _AdminShell extends StatefulWidget {
  const _AdminShell({required this.user, required this.initialIndex});

  final AuthUser user;
  final int initialIndex;

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  final _authController = getIt<AuthController>();

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _destinations.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isWide(context);
    final page = _buildPage();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_selectedIndex].label),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _authController.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  NavigationRail(
                    backgroundColor: const Color(0xFFFFF6FA),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    },
                    minWidth: 88,
                    labelType: NavigationRailLabelType.all,
                    indicatorColor: const Color(0xFFFFE5F0),
                    selectedIconTheme: const IconThemeData(
                      color: Color(0xFFE91E63),
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      color: Color(0xFF7A6874),
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Color(0xFF7A6874),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: IconButton(
                          tooltip: 'Sign out',
                          onPressed: _authController.signOut,
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ),
                    ),
                    destinations: _destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: page),
                ],
              )
            : Column(
                children: [
                  Expanded(child: page),
                  NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    },
                    destinations: _destinations
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            label: item.label,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPage() {
    final controller = getIt<AdminController>();

    switch (_selectedIndex) {
      case 0:
        return _DashboardHomePage(
          controller: controller,
          onOpenSection: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        );
      case 1:
        return _OrdersAdminPage(controller: controller);
      case 2:
        return _MenuItemsAdminPage(controller: controller);
      case 3:
        return _MealSessionsAdminPage(controller: controller);
      case 4:
        return _SettingsAdminPage(controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}

const _destinations = <_AdminDestination>[
  _AdminDestination(label: 'Home', icon: Icons.dashboard_rounded),
  _AdminDestination(label: 'Orders', icon: Icons.receipt_long_rounded),
  _AdminDestination(label: 'Menu items', icon: Icons.lunch_dining_rounded),
  _AdminDestination(label: 'Meal sessions', icon: Icons.schedule_rounded),
  _AdminDestination(label: 'Settings', icon: Icons.settings_rounded),
];

class _AdminDestination {
  const _AdminDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DashboardHomePage extends StatelessWidget {
  const _DashboardHomePage({
    required this.controller,
    required this.onOpenSection,
  });

  final AdminController controller;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminDashboardState>(
      stream: controller.watchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'The dashboard could not load right now: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final state = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting &&
            state == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state == null) {
          return const Center(
            child: Text('Dashboard data will appear here once Firebase syncs.'),
          );
        }

        return _AdminList(
          children: [
            _HeaderCard(
              eyebrow: 'Admin dashboard',
              title: state.businessName,
              subtitle:
                  'Monitor operations, review activity, and jump into the core admin pages.',
              action: FilledButton.icon(
                onPressed: () => onOpenSection(1),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('View orders'),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  title: 'Today\'s orders',
                  value: '${state.todaysOrdersCount}',
                  accent: const Color(0xFFE91E63),
                  icon: Icons.local_shipping_rounded,
                ),
                _MetricCard(
                  title: 'Pending orders',
                  value: '${state.pendingOrdersCount}',
                  accent: const Color(0xFFFF78AB),
                  icon: Icons.pending_actions_rounded,
                ),
                _MetricCard(
                  title: 'Active meal session',
                  value: state.activeMealSessionName,
                  accent: const Color(0xFFF06292),
                  icon: Icons.schedule_rounded,
                ),
                _MetricCard(
                  title: 'Sold out items',
                  value: '${state.soldOutItemsCount}',
                  accent: const Color(0xFFAD1457),
                  icon: Icons.inventory_2_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Business status',
              child: Column(
                children: [
                  _StatusRow(
                    label: 'Ordering',
                    value: state.orderingOpen ? 'Open' : 'Paused',
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Pickup',
                    value: state.pickupEnabled ? 'Enabled' : 'Disabled',
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Banner',
                    value: state.bannerMessage.isEmpty
                        ? 'No active banner'
                        : state.bannerMessage,
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Offer',
                    value: state.activeOffer.isEmpty
                        ? 'No active offer'
                        : state.activeOffer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Quick links',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickActionButton(
                    label: 'Orders',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => onOpenSection(1),
                  ),
                  _QuickActionButton(
                    label: 'Menu items',
                    icon: Icons.lunch_dining_rounded,
                    onTap: () => onOpenSection(2),
                  ),
                  _QuickActionButton(
                    label: 'Meal sessions',
                    icon: Icons.schedule_rounded,
                    onTap: () => onOpenSection(3),
                  ),
                  _QuickActionButton(
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    onTap: () => onOpenSection(4),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrdersAdminPage extends StatelessWidget {
  const _OrdersAdminPage({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderSummary>>(
      stream: controller.watchOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <OrderSummary>[];

        return _AdminList(
          children: [
            const _SimplePageHeader(
              title: 'Orders',
              subtitle:
                  'Track incoming orders and move each one through the kitchen and delivery pipeline.',
            ),
            const SizedBox(height: 18),
            if (orders.isEmpty)
              const _EmptyStateCard(
                message:
                    'No orders found yet. New order activity will appear here.',
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(
                    order: order,
                    onStatusChanged: (status) async {
                      await controller.updateOrderStatus(
                        order.orderNumber.replaceFirst('#', ''),
                        status,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${order.orderNumber} updated to ${_labelize(status)}.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MenuItemsAdminPage extends StatelessWidget {
  const _MenuItemsAdminPage({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuItem>>(
      stream: controller.watchMenuItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <MenuItem>[];

        return _AdminList(
          children: [
            _SimplePageHeader(
              title: 'Menu items',
              subtitle:
                  'Create, edit, and disable items without leaving the admin dashboard.',
              action: FilledButton.icon(
                onPressed: () => _showMenuItemEditor(context, controller),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add item'),
              ),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const _EmptyStateCard(
                message:
                    'No menu items found. Add your first item to start selling.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.categoryName} • ${item.price.toStringAsFixed(0)} • stock ${item.stock} • ${item.isAvailable ? 'available' : 'hidden'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => _showMenuItemEditor(
                              context,
                              controller,
                              existing: item,
                            ),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => controller.deleteMenuItem(item.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MealSessionsAdminPage extends StatelessWidget {
  const _MealSessionsAdminPage({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MealSession>>(
      stream: controller.watchMealSessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <MealSession>[];

        return _AdminList(
          children: [
            _SimplePageHeader(
              title: 'Meal sessions',
              subtitle:
                  'Control which meal windows are active and when customers can see each one.',
              action: FilledButton.icon(
                onPressed: () => _showMealSessionEditor(context, controller),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add session'),
              ),
            ),
            const SizedBox(height: 18),
            if (sessions.isEmpty)
              const _EmptyStateCard(
                message:
                    'No meal sessions found. Add breakfast, lunch, or any custom session here.',
              )
            else
              ...sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(session.name),
                      subtitle: Text(
                        '${_twoDigits(session.startHour)}:${_twoDigits(session.startMinute)} - ${_twoDigits(session.endHour)}:${_twoDigits(session.endMinute)} • ${session.isActive ? 'active' : 'inactive'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => _showMealSessionEditor(
                              context,
                              controller,
                              existing: session,
                            ),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () =>
                                controller.deleteMealSession(session.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SettingsAdminPage extends StatelessWidget {
  const _SettingsAdminPage({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BusinessSettings>(
      stream: controller.watchBusinessSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;

        return _AdminList(
          children: [
            _SimplePageHeader(
              title: 'Settings',
              subtitle:
                  'Business identity, ordering controls, fees, and customer-facing banners live here.',
              action: FilledButton.icon(
                onPressed: settings == null
                    ? null
                    : () => _showSettingsEditor(context, controller, settings),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit settings'),
              ),
            ),
            const SizedBox(height: 18),
            if (settings == null)
              const Center(child: CircularProgressIndicator())
            else
              _SectionCard(
                title: 'Business profile',
                child: Column(
                  children: [
                    _StatusRow(label: 'Business', value: settings.businessName),
                    const SizedBox(height: 12),
                    _StatusRow(label: 'Phone', value: settings.phone),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'Delivery fee',
                      value:
                          '${settings.currency} ${settings.deliveryFee.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'Tax rate',
                      value: '${settings.taxRate.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'Ordering',
                      value: settings.orderingOpen ? 'Open' : 'Closed',
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'Pickup',
                      value: settings.pickupEnabled ? 'Enabled' : 'Disabled',
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      label: 'Opening hours note',
                      value: settings.openingHoursNote,
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(label: 'Banner', value: settings.bannerMessage),
                    const SizedBox(height: 12),
                    _StatusRow(label: 'Offer', value: settings.activeOffer),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SimplePageHeader extends StatelessWidget {
  const _SimplePageHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        ...switch (action) {
          final Widget action => [action],
          null => const <Widget>[],
        },
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5F0), Color(0xFFFFF6FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFF4C7D9)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE91E63),
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF2B2130),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6E5B67)),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdminList extends StatelessWidget {
  const _AdminList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width < 360
        ? 16.0
        : width < Breakpoints.compact
        ? 20.0
        : 32.0;
    final maxContentWidth = width < Breakpoints.wide ? double.infinity : 720.0;

    return ListView(
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
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = Breakpoints.isCompact(context);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = Breakpoints.isCompact(context);

    return SizedBox(
      width: isCompact ? double.infinity : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onStatusChanged});

  final OrderSummary order;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Last update: ${order.updatedAt}'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrderStatuses.values
                  .map(
                    (status) => ChoiceChip(
                      label: Text(_labelize(status)),
                      selected: order.stage == status,
                      onSelected: (_) => onStatusChanged(status),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}

Future<void> _showMenuItemEditor(
  BuildContext context,
  AdminController controller, {
  MenuItem? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final descriptionController = TextEditingController(
    text: existing?.description ?? '',
  );
  final priceController = TextEditingController(
    text: existing == null ? '' : existing.price.toStringAsFixed(0),
  );
  final categoryController = TextEditingController(
    text: existing?.categoryName ?? 'General',
  );
  final imageUrlController = TextEditingController(
    text: existing?.imageUrl ?? '',
  );
  final localAssetController = TextEditingController(
    text: existing?.localImageAsset ?? '',
  );
  final stockController = TextEditingController(
    text: existing == null ? '0' : '${existing.stock}',
  );
  final prepTimeController = TextEditingController(
    text: existing == null ? '15' : '${existing.prepTimeMinutes}',
  );
  final formKey = GlobalKey<FormState>();
  var isAvailable = existing?.isAvailable ?? true;
  String? selectedMealSessionId = existing?.mealSessionId;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StreamBuilder<List<MealSession>>(
        stream: controller.watchMealSessions(),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? const <MealSession>[];
          final hasSelection = sessions.any(
            (session) => session.id == selectedMealSessionId,
          );
          if (!hasSelection) {
            selectedMealSessionId = sessions.isEmpty ? null : sessions.first.id;
          }

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          existing == null ? 'Add menu item' : 'Edit menu item',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item name',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.hasError) ...[
                          Text(
                            'Unable to load meal sessions. Check Firestore rules and admin claims.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else if (sessions.isEmpty) ...[
                          const Text(
                            'No meal sessions yet. Add one in the Meal sessions tab.',
                          ),
                          const SizedBox(height: 12),
                        ],
                        DropdownButtonFormField<String>(
                          value: selectedMealSessionId,
                          hint: const Text('Select a meal session'),
                          items: sessions
                              .map(
                                (session) => DropdownMenuItem<String>(
                                  value: session.id,
                                  child: Text(session.name),
                                ),
                              )
                              .toList(),
                          onChanged: sessions.isEmpty || snapshot.hasError
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    selectedMealSessionId = value;
                                  });
                                },
                          decoration: const InputDecoration(
                            labelText: 'Meal session',
                          ),
                          validator: (_) {
                            if (sessions.isEmpty) {
                              return 'Create a meal session first.';
                            }
                            if (selectedMealSessionId == null ||
                                selectedMealSessionId!.isEmpty) {
                              return 'Select a meal session.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(labelText: 'Stock'),
                          keyboardType: TextInputType.number,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: prepTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Prep time (minutes)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: localAssetController,
                          decoration: const InputDecoration(
                            labelText: 'Local asset path',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: isAvailable,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Available'),
                          onChanged: (value) {
                            setSheetState(() {
                              isAvailable = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            try {
                              await controller.saveMenuItem(
                                MenuItem(
                                  id: existing?.id ?? _newId('menu'),
                                  name: nameController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                  price:
                                      double.tryParse(
                                        priceController.text.trim(),
                                      ) ??
                                      0,
                                  imageUrl: imageUrlController.text.trim(),
                                  localImageAsset: localAssetController.text
                                      .trim(),
                                  categoryName: categoryController.text.trim(),
                                  mealSessionId: selectedMealSessionId ?? '',
                                  isAvailable: isAvailable,
                                  stock:
                                      int.tryParse(
                                        stockController.text.trim(),
                                      ) ??
                                      0,
                                  prepTimeMinutes:
                                      int.tryParse(
                                        prepTimeController.text.trim(),
                                      ) ??
                                      0,
                                ),
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to save menu item: $error',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            existing == null ? 'Create item' : 'Save changes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Future<void> _showMealSessionEditor(
  BuildContext context,
  AdminController controller, {
  MealSession? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final startHourController = TextEditingController(
    text: existing == null ? '9' : '${existing.startHour}',
  );
  final startMinuteController = TextEditingController(
    text: existing == null ? '0' : '${existing.startMinute}',
  );
  final endHourController = TextEditingController(
    text: existing == null ? '11' : '${existing.endHour}',
  );
  final endMinuteController = TextEditingController(
    text: existing == null ? '0' : '${existing.endMinute}',
  );
  final formKey = GlobalKey<FormState>();
  var isActive = existing?.isActive ?? true;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? 'Add meal session'
                          : 'Edit meal session',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Session name',
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: startHourController,
                      decoration: const InputDecoration(
                        labelText: 'Start hour',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: startMinuteController,
                      decoration: const InputDecoration(
                        labelText: 'Start minute',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: endHourController,
                      decoration: const InputDecoration(labelText: 'End hour'),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: endMinuteController,
                      decoration: const InputDecoration(
                        labelText: 'End minute',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      onChanged: (value) {
                        setSheetState(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        try {
                          await controller.saveMealSession(
                            MealSession(
                              id: existing?.id ?? _newId('session'),
                              name: nameController.text.trim(),
                              startHour:
                                  int.tryParse(
                                    startHourController.text.trim(),
                                  ) ??
                                  0,
                              startMinute:
                                  int.tryParse(
                                    startMinuteController.text.trim(),
                                  ) ??
                                  0,
                              endHour:
                                  int.tryParse(
                                    endHourController.text.trim(),
                                  ) ??
                                  0,
                              endMinute:
                                  int.tryParse(
                                    endMinuteController.text.trim(),
                                  ) ??
                                  0,
                              isActive: isActive,
                            ),
                          );
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save meal session: $error',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        existing == null ? 'Create session' : 'Save changes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showSettingsEditor(
  BuildContext context,
  AdminController controller,
  BusinessSettings existing,
) {
  final businessNameController = TextEditingController(
    text: existing.businessName,
  );
  final phoneController = TextEditingController(text: existing.phone);
  final deliveryFeeController = TextEditingController(
    text: existing.deliveryFee.toStringAsFixed(0),
  );
  final taxRateController = TextEditingController(
    text: existing.taxRate.toStringAsFixed(1),
  );
  final currencyController = TextEditingController(text: existing.currency);
  final openingHoursController = TextEditingController(
    text: existing.openingHoursNote,
  );
  final bannerController = TextEditingController(text: existing.bannerMessage);
  final offerController = TextEditingController(text: existing.activeOffer);
  final formKey = GlobalKey<FormState>();
  var pickupEnabled = existing.pickupEnabled;
  var orderingOpen = existing.orderingOpen;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business name',
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currencyController,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deliveryFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery fee',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: taxRateController,
                      decoration: const InputDecoration(labelText: 'Tax rate'),
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Opening hours note',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bannerController,
                      decoration: const InputDecoration(labelText: 'Banner'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: offerController,
                      decoration: const InputDecoration(
                        labelText: 'Active offer',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: orderingOpen,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ordering open'),
                      onChanged: (value) {
                        setSheetState(() {
                          orderingOpen = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      value: pickupEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pickup enabled'),
                      onChanged: (value) {
                        setSheetState(() {
                          pickupEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        await controller.saveBusinessSettings(
                          BusinessSettings(
                            businessName: businessNameController.text.trim(),
                            phone: phoneController.text.trim(),
                            deliveryFee:
                                double.tryParse(
                                  deliveryFeeController.text.trim(),
                                ) ??
                                0,
                            taxRate:
                                double.tryParse(
                                  taxRateController.text.trim(),
                                ) ??
                                0,
                            currency: currencyController.text.trim(),
                            pickupEnabled: pickupEnabled,
                            orderingOpen: orderingOpen,
                            openingHoursNote: openingHoursController.text
                                .trim(),
                            bannerMessage: bannerController.text.trim(),
                            activeOffer: offerController.text.trim(),
                          ),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save settings'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String _newId(String prefix) {
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}

String _labelize(String value) {
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
