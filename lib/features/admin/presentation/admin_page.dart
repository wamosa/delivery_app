import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../application/admin_controller.dart';
import '../domain/admin_dashboard_state.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminController();

    return StreamBuilder<AdminDashboardState>(
      stream: controller.watchDashboard(),
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting &&
            state == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Dashboard data will appear here once Firebase syncs.',
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F0EA),
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _HeroBanner(state: state),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    title: 'Today\'s Orders',
                    value: '${state.todaysOrdersCount}',
                    accent: const Color(0xFF2E8B57),
                    icon: Icons.receipt_long_rounded,
                  ),
                  _MetricCard(
                    title: 'Pending Orders',
                    value: '${state.pendingOrdersCount}',
                    accent: const Color(0xFFE97924),
                    icon: Icons.pending_actions_rounded,
                  ),
                  _MetricCard(
                    title: 'Active Session',
                    value: state.activeMealSessionName,
                    accent: const Color(0xFF7C4DFF),
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  _MetricCard(
                    title: 'Sold Out Items',
                    value: '${state.soldOutItemsCount}',
                    accent: const Color(0xFFD32F2F),
                    icon: Icons.remove_shopping_cart_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionCard(
                title: 'Business Status',
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
                    if (state.bannerMessage.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _StatusRow(label: 'Banner', value: state.bannerMessage),
                    ],
                    if (state.activeOffer.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Active Offer',
                        value: state.activeOffer,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Quick Actions',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionButton(
                      label: 'Orders Board',
                      icon: Icons.view_kanban_rounded,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.orders),
                    ),
                    _QuickActionButton(
                      label: 'Meal Sessions',
                      icon: Icons.schedule_rounded,
                      onTap: () =>
                          _showComingSoon(context, 'Meal session management'),
                    ),
                    _QuickActionButton(
                      label: 'Menu Items',
                      icon: Icons.lunch_dining_rounded,
                      onTap: () => _showComingSoon(context, 'Menu management'),
                    ),
                    _QuickActionButton(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      onTap: () => _showComingSoon(context, 'Admin settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName is the next admin module to build.'),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22223B), Color(0xFF4A4E69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.businessName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor operations, session health, and order flow in real time.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFE7E5F0)),
          ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
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
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6772)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6772)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
