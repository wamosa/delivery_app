import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_line_item.dart';
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
  final CartController _cartController = getIt<CartController>();
  final TextEditingController _addressController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLocating = false;
  String? _message;
  String? _locationMessage;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _controller.loadPreview();

    return FeatureScaffold(
      title: 'Checkout',
      subtitle:
          'Place address capture, payment selection, and order confirmation logic here.',
      children: [
        ValueListenableBuilder<List<CartLineItem>>(
          valueListenable: _cartController.watchItems(),
          builder: (context, items, _) {
            if (items.isEmpty) {
              return const InfoCard(
                title: 'Your cart is empty',
                description: 'Add items from the menu to place an order.',
              );
            }

            final summary = _cartController.loadSummary();
            final itemLines = items
                .map(
                  (entry) =>
                      '${entry.quantity}x ${entry.item.name} • KSh ${entry.lineTotal.toStringAsFixed(0)}',
                )
                .join('\n');

            return InfoCard(
              title: 'Cart items',
              description:
                  '$itemLines\n\nSubtotal ${summary.subtotalLabel} • Delivery ${summary.deliveryFeeLabel} • Total ${summary.totalLabel}',
            );
          },
        ),
        InfoCard(
          title: 'Delivery details',
          description:
              'Enter a readable address and capture your current location for delivery.',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                  hintText: 'e.g. Westlands, Nairobi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLocating ? null : _captureLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(
                  _isLocating ? 'Locating...' : 'Use current location',
                ),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                ),
              ],
              if (_locationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final items = _cartController.items;
    if (items.isEmpty) {
      setState(() {
        _message = 'Your cart is empty. Add items before checkout.';
      });
      return;
    }
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _message = 'Please enter a delivery address.';
      });
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() {
        _message = 'Please capture your delivery location.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final result = await _controller.placeOrder(
        PlaceOrderRequest(
          items: items
              .map(
                (entry) => PlaceOrderItem(
                  itemId: entry.item.id,
                  quantity: entry.quantity,
                ),
              )
              .toList(),
          deliveryType: 'delivery',
          address: address,
          deliveryLatitude: _latitude,
          deliveryLongitude: _longitude,
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _message =
            'Your order has been made. Order ${result.orderId} received with status ${result.status}.';
      });
      _cartController.clear();
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

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Location services are disabled.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission was denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = null;
      });
    } catch (error) {
      setState(() {
        _locationMessage = 'Failed to get location: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }
}
