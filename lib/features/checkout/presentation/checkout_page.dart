import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/app_routes.dart';
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
  String _deliveryType = 'delivery';
  String _paymentMethod = 'M-Pesa';
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
    return FeatureScaffold(
      title: 'Checkout',
      subtitle: 'Confirm delivery details and place your order.',
      showThemeToggle: false,
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

            final summary = _cartController.loadSummary(
              deliveryFee: _deliveryType == 'pickup' ? 0 : 180,
            );
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
          title: 'Order type',
          description: 'Choose delivery or pickup.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Delivery'),
                selected: _deliveryType == 'delivery',
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _deliveryType = 'delivery';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Pickup'),
                selected: _deliveryType == 'pickup',
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _deliveryType = 'pickup';
                    _locationMessage = null;
                  });
                },
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'Delivery details',
          description:
              _deliveryType == 'pickup'
                  ? 'Add a note for pickup (optional).'
                  : 'Enter a readable address and capture your current location for delivery.',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery address or pickup note',
                  hintText: 'e.g. Westlands, Nairobi',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_deliveryType == 'delivery') ...[
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
          title: 'Payment method',
          description: 'Select how you want to pay.',
          trailing: DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')),
              DropdownMenuItem(value: 'Cash', child: Text('Cash on delivery')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _paymentMethod = value;
              });
            },
          ),
        ),
        InfoCard(
          title: 'Confirm order',
          description: _message ??
              'Tap the button to place your order. You will be redirected to Orders.',
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
    if (_deliveryType == 'delivery') {
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
          deliveryType: _deliveryType,
          address: address.isEmpty ? 'Pickup' : address,
          deliveryLatitude: _deliveryType == 'delivery' ? _latitude : null,
          deliveryLongitude: _deliveryType == 'delivery' ? _longitude : null,
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
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orders,
        arguments: {
          'orderId': result.orderId,
          'status': result.status,
        },
      );
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
