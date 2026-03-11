import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/orders_controller.dart';
import '../domain/order_summary.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OrdersController();

    return FutureBuilder<List<OrderSummary>>(
      future: controller.loadOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <OrderSummary>[];
        return FeatureScaffold(
          title: 'Orders',
          subtitle:
              'Tracking, history, reorder, rider updates, and customer support hooks belong here.',
          children: orders
              .map(
                (order) => InfoCard(
                  title: order.orderNumber,
                  description: '${order.stage} • ${order.updatedAt}',
                ),
              )
              .toList(),
        );
      },
    );
  }
}
