import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/cart_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = getIt<CartController>().loadSummary();

    return FeatureScaffold(
      title: 'Cart',
      subtitle:
          'This feature owns selected items, promo codes, fees, and validation before checkout.',
      children: [
        InfoCard(
          title: '${summary.itemCount} items ready for checkout',
          description:
              'Subtotal ${summary.subtotalLabel} • Delivery ${summary.deliveryFeeLabel} • Total ${summary.totalLabel}',
        ),
      ],
    );
  }
}
