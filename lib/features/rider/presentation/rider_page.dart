import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../orders/application/orders_controller.dart';
import '../../orders/domain/order_statuses.dart';
import '../../orders/domain/order_summary.dart';

class RiderPage extends StatefulWidget {
  const RiderPage({super.key});

  @override
  State<RiderPage> createState() => _RiderPageState();
}

class _RiderPageState extends State<RiderPage> {
  late final OrdersController _controller;
  late final Stream<List<OrderSummary>> _ordersStream;
  StreamSubscription<List<OrderSummary>>? _ordersSub;
  StreamSubscription<Position>? _positionSub;
  Set<String> _trackingOrderIds = {};

  @override
  void initState() {
    super.initState();
    _controller = getIt<OrdersController>();
    _ordersStream = _controller.watchAssignedOrders().asBroadcastStream();
    _ordersSub = _ordersStream.listen(_handleOrdersUpdate);
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _handleOrdersUpdate(List<OrderSummary> orders) async {
    final nextTrackingIds = orders
        .where(
          (order) =>
              order.trackRiderLocation &&
              order.stage == OrderStatuses.outForDelivery,
        )
        .map((order) => order.orderId)
        .toSet();

    if (nextTrackingIds.isEmpty) {
      _trackingOrderIds = {};
      await _stopLocationTracking();
      return;
    }

    _trackingOrderIds = nextTrackingIds;
    await _ensureLocationTracking();
  }

  Future<void> _stopLocationTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _ensureLocationTracking() async {
    if (_positionSub != null) {
      return;
    }

    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        for (final orderId in _trackingOrderIds) {
          _controller.updateRiderLocation(
            orderId: orderId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      },
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showSnack('Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnack('Location permission was denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permission is permanently denied.');
      return false;
    }

    return true;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
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
          stream: _ordersStream,
          builder: (context, snapshot) {
            final orders = snapshot.data ?? const <OrderSummary>[];
            final newOrders = orders
                .where((order) => order.stage == OrderStatuses.ready)
                .toList();
            final activeDeliveries = orders
                .where((order) => order.stage == OrderStatuses.outForDelivery)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Rider Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick up assigned orders, update delivery progress, and confirm drop-offs.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF8A7F8F)),
                ),
                const SizedBox(height: 18),
                _RiderSectionCard(
                  title: 'New Orders',
                  count: newOrders.length,
                  emptyTitle: 'No assigned orders',
                  emptyMessage:
                      'Orders assigned to you will appear here once the admin assigns them.',
                  orders: newOrders,
                ),
                const SizedBox(height: 18),
                _RiderSectionCard(
                  title: 'Active Deliveries',
                  count: activeDeliveries.length,
                  emptyTitle: 'No active deliveries',
                  emptyMessage:
                      'You will see active deliveries here after pickup.',
                  orders: activeDeliveries,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RiderSectionCard extends StatelessWidget {
  const _RiderSectionCard({
    required this.title,
    required this.count,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.orders,
  });

  final String title;
  final int count;
  final String emptyTitle;
  final String emptyMessage;
  final List<OrderSummary> orders;

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
                    color: const Color(0xFFE9E1EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF2F7B50),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              _EmptyState(
                title: emptyTitle,
                message: emptyMessage,
              )
            else
              ...orders.map((order) => _RiderOrderRow(order: order)),
          ],
        ),
      ),
    );
  }
}

class _RiderOrderRow extends StatelessWidget {
  const _RiderOrderRow({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress ?? 'No address provided';
    final canNavigate =
        order.deliveryLatitude != null && order.deliveryLongitude != null;
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
                  '$address • ${order.stage}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF8A7F8F)),
                ),
              ],
            ),
          ),
          if (canNavigate) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _openGoogleMaps(
                context,
                order.deliveryLatitude!,
                order.deliveryLongitude!,
              ),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openGoogleMaps(
  BuildContext context,
  double latitude,
  double longitude,
) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Google Maps.')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Icon(
            Icons.delivery_dining_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF8A7F8F)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
