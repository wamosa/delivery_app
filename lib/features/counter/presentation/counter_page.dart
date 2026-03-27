import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/role_drawer.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../auth/domain/auth_user.dart';
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      drawer: const RoleDrawer(selectedRoute: AppRoutes.counter),
      body: SafeArea(
        child: StreamBuilder<List<AuthUser>>(
          stream: controller.watchRiders(),
          builder: (context, ridersSnapshot) {
            final riders = ridersSnapshot.data ?? const <AuthUser>[];
            return StreamBuilder<List<OrderSummary>>(
              stream: controller.watchAdminOrders(),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? const <OrderSummary>[];
                final incoming = orders.where(
                  (order) =>
                      order.stage == OrderStatuses.pending ||
                      order.stage == OrderStatuses.accepted,
                );
                final preparing = orders.where(
                  (order) => order.stage == OrderStatuses.preparing,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final orderList = ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Counter Dashboard',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                          riders: riders,
                          actionLabel: 'Send to Kitchen',
                          onAction: (order) => controller.updateOrderStatus(
                            order.orderNumber.replaceFirst('#', ''),
                            OrderStatuses.preparing,
                          ),
                          onAssignRider: (order, rider) =>
                              controller.assignOrderToRider(
                            orderId: order.orderId,
                            rider: rider,
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
                          riders: riders,
                          actionLabel: 'Mark as Pickup Ready',
                          onAction: (order) => controller.updateOrderStatus(
                            order.orderNumber.replaceFirst('#', ''),
                            OrderStatuses.ready,
                          ),
                          onAssignRider: (order, rider) =>
                              controller.assignOrderToRider(
                            orderId: order.orderId,
                            rider: rider,
                          ),
                        ),
                      ],
                    );

                    final riderPanel = _RiderSidePanel(
                      riders: riders,
                      orders: orders,
                    );

                    if (!isWide) {
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: 920,
                            child: orderList,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: riderPanel,
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: orderList),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 360,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, right: 20),
                            child: riderPanel,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
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
    required this.riders,
    required this.actionLabel,
    required this.onAction,
    required this.onAssignRider,
  });

  final String title;
  final int count;
  final Color badgeColor;
  final Color actionColor;
  final String emptyMessage;
  final List<OrderSummary> orders;
  final List<AuthUser> riders;
  final String actionLabel;
  final void Function(OrderSummary order) onAction;
  final void Function(OrderSummary order, AuthUser rider) onAssignRider;

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
                  riders: riders,
                  onAction: () => onAction(order),
                  onAssignRider: (rider) => onAssignRider(order, rider),
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
    required this.riders,
    required this.onAction,
    required this.onAssignRider,
  });

  final OrderSummary order;
  final String actionLabel;
  final Color actionColor;
  final List<AuthUser> riders;
  final VoidCallback onAction;
  final ValueChanged<AuthUser> onAssignRider;

  @override
  Widget build(BuildContext context) {
    final assignedLabel = order.assignedRiderName?.isNotEmpty == true
        ? order.assignedRiderName!
        : order.assignedRiderEmail;
    final requestedLabel = order.requestedRiderName?.isNotEmpty == true
        ? order.requestedRiderName!
        : order.requestedRiderEmail;

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
                if (assignedLabel != null && assignedLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned: $assignedLabel',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFF6E5B67)),
                  ),
                ],
                if (requestedLabel != null &&
                    requestedLabel.isNotEmpty &&
                    (assignedLabel == null || assignedLabel.isEmpty)) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: $requestedLabel',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFF6E5B67)),
                  ),
                ],
                if (riders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AuthUser>(
                    value: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Assign rider',
                    ),
                    items: riders
                        .map(
                          (rider) => DropdownMenuItem<AuthUser>(
                            value: rider,
                            child: Text(
                              rider.name.isEmpty ? rider.email : rider.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (rider) {
                      if (rider == null) {
                        return;
                      }
                      onAssignRider(rider);
                    },
                  ),
                ],
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

class _RiderSidePanel extends StatelessWidget {
  const _RiderSidePanel({
    required this.riders,
    required this.orders,
  });

  final List<AuthUser> riders;
  final List<OrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rider Availability',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign riders manually to incoming orders.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF8A7F8F)),
            ),
            const SizedBox(height: 16),
            if (riders.isEmpty)
              Text(
                'No riders found yet.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF8A7F8F)),
              )
            else
              ...riders.map((rider) {
                final assignedCount = orders
                    .where((order) => order.assignedRiderId == rider.id)
                    .length;
                final label = rider.name.isEmpty ? rider.email : rider.name;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.delivery_dining_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignedCount == 0
                                  ? 'Available'
                                  : 'Assigned $assignedCount order(s)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: const Color(0xFF6E5B67)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: assignedCount == 0
                              ? const Color(0xFFE6F4EA)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          assignedCount == 0 ? 'Free' : 'Busy',
                          style: TextStyle(
                            color: assignedCount == 0
                                ? const Color(0xFF2F7B50)
                                : const Color(0xFFC97B2A),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
