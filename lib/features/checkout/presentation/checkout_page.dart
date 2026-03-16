import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/checkout_controller.dart';
import '../domain/place_order_item.dart';
import '../domain/place_order_request.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CheckoutController _controller = getIt<CheckoutController>();
  bool _isSubmitting = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final preview = _controller.loadPreview();

    return FeatureScaffold(
      title: 'Checkout',
      subtitle:
          'Place address capture, payment selection, and order confirmation logic here.',
      children: [
        InfoCard(
          title: 'Order preview',
          description:
              'Deliver to ${preview.address} • Pay with ${preview.paymentMethod} • ETA ${preview.eta}',
        ),
        InfoCard(
          title: 'Backend-protected checkout',
          description: _message ??
              'Tap the button to place a sample order through Cloud Functions. The server will re-check the meal session and stock before saving the order.',
          trailing: FilledButton(
            onPressed: _isSubmitting ? null : _submitSampleOrder,
            child: Text(_isSubmitting ? 'Placing...' : 'Place order'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitSampleOrder() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final result = await _controller.placeOrder(
        const PlaceOrderRequest(
          items: [
            PlaceOrderItem(itemId: 'chicken-biryani', quantity: 1),
          ],
          deliveryType: 'delivery',
          address: 'Westlands, Nairobi',
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _message =
            'Order ${result.orderId} created. Total KSh ${result.total.toStringAsFixed(0)} with status ${result.status}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Order failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
