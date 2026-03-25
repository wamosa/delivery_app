import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../orders/application/orders_controller.dart';
import '../../orders/domain/order_statuses.dart';
import '../../orders/domain/order_summary.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<OrdersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
        actions: [
          const ThemeModeToggleButton(),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<OrderSummary>>(
          stream: controller.watchAdminOrders(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? const <OrderSummary>[];
            final incoming = orders.where(
              (order) =>
                  order.stage == OrderStatuses.pending ||
                  order.stage == OrderStatuses.accepted,
            );
            final preparing =
                orders.where((order) => order.stage == OrderStatuses.preparing);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Counter Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Receive new orders, confirm payment, coordinate preparation, and the kitchen workflow.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF8A7F8F)),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Incoming Orders',
                  count: incoming.length,
                  badgeColor: const Color(0xFF2F7B50),
                  actionColor: const Color(0xFF2F7B50),
                  emptyMessage: 'No new orders right now.',
                  orders: incoming.toList(),
                  actionLabel: 'Send to Kitchen',
                  onAction: (order) => controller.updateOrderStatus(
                    order.orderNumber.replaceFirst('#', ''),
                    OrderStatuses.preparing,
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Handover Ready',
                  count: preparing.length,
                  badgeColor: const Color(0xFFC97B2A),
                  actionColor: const Color(0xFF2F7B50),
                  emptyMessage: 'No orders waiting for pickup yet.',
                  orders: preparing.toList(),
                  actionLabel: 'Mark as Pickup Ready',
                  onAction: (order) => controller.updateOrderStatus(
                    order.orderNumber.replaceFirst('#', ''),
                    OrderStatuses.ready,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.count,
    required this.badgeColor,
    required this.actionColor,
    required this.emptyMessage,
    required this.orders,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final int count;
  final Color badgeColor;
  final Color actionColor;
  final String emptyMessage;
  final List<OrderSummary> orders;
  final String actionLabel;
  final void Function(OrderSummary order) onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_dining_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '$count orders',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF8A7F8F)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: const Color(0xFF8A7F8F)),
              )
            else
              ...orders.map(
                (order) => _OrderRow(
                  order: order,
                  actionLabel: actionLabel,
                  actionColor: actionColor,
                  onAction: () => onAction(order),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  final OrderSummary order;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE9E1EA),
            child: Text(
              order.orderNumber.replaceFirst('#', '').isEmpty
                  ? '#'
                  : order.orderNumber.replaceFirst('#', '').substring(0, 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.stage} • ${order.updatedAt}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF8A7F8F)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: actionColor,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
