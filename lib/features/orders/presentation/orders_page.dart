import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/orders_controller.dart';
import '../domain/order_summary.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<OrdersController>();
    final args = ModalRoute.of(context)?.settings.arguments;
    final bannerMessage = _buildBannerMessage(args);

    return FutureBuilder<List<OrderSummary>>(
      future: controller.loadOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <OrderSummary>[];
        final cards = <Widget>[
          if (bannerMessage != null)
            InfoCard(
              title: 'Order received',
              description: bannerMessage,
            ),
          ...orders.map(
            (order) => InfoCard(
              title: order.orderNumber,
              description: '${order.stage} • ${order.updatedAt}',
            ),
          ),
        ];
        return FeatureScaffold(
          title: 'Orders',
          subtitle:
              'Tracking, history, reorder, rider updates, and customer support hooks belong here.',
          showThemeToggle: false,
          children: cards,
        );
      },
    );
  }

  static String? _buildBannerMessage(Object? args) {
    if (args is! Map) {
      return null;
    }
    final orderId = args['orderId'] as String?;
    final status = args['status'] as String?;
    if (orderId == null || orderId.isEmpty) {
      return null;
    }
    final statusLabel = (status == null || status.isEmpty) ? 'received' : status;
    return 'Order #$orderId is $statusLabel. You can track updates below.';
  }
}
