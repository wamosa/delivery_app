import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../../orders/application/orders_controller.dart';
import '../../orders/domain/order_summary.dart';

class RiderPage extends StatelessWidget {
  const RiderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<OrdersController>();

    return FeatureScaffold(
      title: 'Rider Dashboard',
      subtitle:
          'Pick up assigned orders, update delivery progress, and confirm drop-offs.',
      children: [
        StreamBuilder<List<OrderSummary>>(
          stream: controller.watchAssignedOrders(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? const <OrderSummary>[];

            if (orders.isEmpty) {
              return const InfoCard(
                title: 'No assigned orders',
                description:
                    'Orders assigned to you will appear here once the admin assigns them.',
              );
            }

            return Column(
              children: orders
                  .map(
                    (order) => InfoCard(
                      title: order.orderNumber,
                      description: _buildRiderDescription(order),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  static String _buildRiderDescription(OrderSummary order) {
    final address = order.deliveryAddress ?? 'No address provided';
    final coords = (order.deliveryLatitude != null &&
            order.deliveryLongitude != null)
        ? '(${order.deliveryLatitude!.toStringAsFixed(5)}, ${order.deliveryLongitude!.toStringAsFixed(5)})'
        : 'No coordinates yet';
    return '$address • $coords • Status: ${order.stage}';
  }
}
