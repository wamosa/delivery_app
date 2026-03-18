import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/data/business_settings_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/notification_service.dart';
import '../../admin/domain/business_settings.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_line_item.dart';
import '../application/menu_controller.dart' as menu_feature;
import '../application/menu_screen_state.dart';
import '../domain/menu_item.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final menu_feature.MenuController _menuController =
      getIt<menu_feature.MenuController>();
  final AuthController _authController = getIt<AuthController>();
  final CartController _cartController = getIt<CartController>();
  final NotificationService _notificationService =
      getIt<NotificationService>();
  final Set<String> _favoriteItemIds = <String>{};
  String _searchQuery = '';
  String _selectedCategory = 'All Food';

  String _formatSessionTime(BuildContext context, int hour, int minute) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: false,
    );
  }

  String _buildSubtitle(BuildContext context, MenuScreenState state) {
    final session = state.displaySession;
    if (session == null) {
      return 'Menu times will appear here once meal sessions are available.';
    }

    if (state.activeSession != null) {
      return 'Now serving ${session.name} until '
          '${_formatSessionTime(context, session.endHour, session.endMinute)}.';
    }

    final startTime = _formatSessionTime(
      context,
      session.startHour,
      session.startMinute,
    );
    return '${session.name} starts at $startTime. Browse now while the kitchen preps.';
  }

  String _disabledOrderingMessage(
    BusinessSettings settings,
    MenuScreenState state,
  ) {
    if (!settings.orderingOpen) {
      return 'Ordering is paused right now. Please check back soon.';
    }

    if (state.displaySession == null) {
      return 'No meal session is available right now.';
    }

    if (state.activeSession == null) {
      return 'Ordering opens when ${state.displaySession!.name} starts.';
    }

    return 'This item is not available right now.';
  }

  List<String> _buildCategories(List<MenuItem> items) {
    final categories = items.map((item) => item.categoryName).toSet().toList()
      ..sort();
    return ['All Food', ...categories];
  }

  List<MenuItem> _filterItems(List<MenuItem> items) {
    final query = _searchQuery.trim().toLowerCase();
    return items.where((item) {
      final matchesCategory =
          _selectedCategory == 'All Food' ||
          item.categoryName == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _toggleFavorite(String itemId) {
    setState(() {
      if (!_favoriteItemIds.add(itemId)) {
        _favoriteItemIds.remove(itemId);
      }
    });
  }

  void _showMenuDetails(
    MenuItem item, {
    required BusinessSettings settings,
    required MenuScreenState state,
  }) {
    final addOns = _dummyAddOnsFor(item.mealSessionId);
    var quantity = 1;
    var selectedSize = 'Medium';
    final selectedAddOns = <String>{};
    final canOrder = settings.orderingOpen && state.activeSession != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sizeMultiplier = _sizeMultipliers[selectedSize] ?? 1.0;
            final addOnCost = selectedAddOns.fold<double>(
              0,
              (sum, addOn) => sum + (_dummyAddOnPrice(addOn)),
            );
            final total =
                ((item.price * sizeMultiplier) + addOnCost) * quantity;

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8D1C7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE5F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '4.5 (1.2k)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD61A6F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: [
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            color: const Color(0xFF8BC34A),
                            label: '${item.prepTimeMinutes} min',
                          ),
                          _InfoPill(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF7043),
                            label: _dummyCaloriesFor(item),
                          ),
                          _InfoPill(
                            icon: Icons.restaurant_menu_rounded,
                            color: const Color(0xFFE9A03B),
                            label: item.categoryName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: _FoodImage(item: item, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Size',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _sizeMultipliers.keys.map((size) {
                          return _ChoiceChipButton(
                            label: size,
                            selected: selectedSize == size,
                            onTap: () {
                              setSheetState(() {
                                selectedSize = size;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Additional Ingredients',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: addOns.map((addOn) {
                          final isSelected = selectedAddOns.contains(addOn);
                          return _ChoiceChipButton(
                            label:
                                '$addOn (+${_dummyAddOnPrice(addOn).toStringAsFixed(0)})',
                            selected: isSelected,
                            onTap: () {
                              setSheetState(() {
                                if (!selectedAddOns.add(addOn)) {
                                  selectedAddOns.remove(addOn);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _SheetQuantitySelector(
                            quantity: quantity,
                            onDecrement: () {
                              setSheetState(() {
                                if (quantity > 1) {
                                  quantity -= 1;
                                }
                              });
                            },
                            onIncrement: () {
                              setSheetState(() {
                                quantity += 1;
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Price',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF726B63),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'KSh ${total.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: canOrder
                              ? () {
                                  for (var i = 0; i < quantity; i++) {
                                    _cartController.addItem(item);
                                  }
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$quantity x ${item.name} added to cart.',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                          ),
                          label: Text(
                            canOrder
                                ? 'Add $quantity to Cart'
                                : 'Ordering unavailable',
                          ),
                        ),
                      ),
                      if (!canOrder) ...[
                        const SizedBox(height: 12),
                        Text(
                          _disabledOrderingMessage(settings, state),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF6E5B67)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _dummyAddOnsFor(String sessionId) {
    switch (sessionId) {
      case 'breakfast':
        return const ['Extra Tea', 'Honey', 'Fruit'];
      case 'lunch':
        return const ['Kachumbari', 'Avocado', 'Chapati'];
      case 'snacks':
        return const ['Chili Sauce', 'Sausage', 'Ketchup'];
      default:
        return const ['Chef Special'];
    }
  }

  double _dummyAddOnPrice(String addOn) {
    switch (addOn) {
      case 'Honey':
      case 'Fruit':
      case 'Ketchup':
        return 30;
      case 'Extra Tea':
      case 'Kachumbari':
      case 'Chili Sauce':
        return 40;
      case 'Avocado':
      case 'Sausage':
      case 'Chapati':
        return 60;
      default:
        return 35;
    }
  }

  String _dummyCaloriesFor(MenuItem item) {
    switch (item.mealSessionId) {
      case 'breakfast':
        return '280 Kcal';
      case 'lunch':
        return '520 Kcal';
      case 'snacks':
        return '340 Kcal';
      default:
        return '300 Kcal';
    }
  }

  Future<void> _handleAccountSelection(String value) async {
    switch (value) {
      case 'sign_in':
        if (!mounted) {
          return;
        }
        await Navigator.pushNamed(context, AppRoutes.auth);
        break;
      case 'sign_out':
        await _authController.signOut();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BusinessSettings>(
      stream: _menuController.watchBusinessSettings(),
      initialData: BusinessSettingsRepository.defaultSettings,
      builder: (context, snapshot) {
        final settings =
            snapshot.data ?? BusinessSettingsRepository.defaultSettings;

        return StreamBuilder<MenuScreenState>(
          stream: _menuController.watchMenuScreenState(),
          builder: (context, snapshot) {
            final state = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting &&
                state == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final resolvedState =
                state ??
                MenuScreenState(
                  now: DateTime.now(),
                  sessions: const [],
                  activeSession: null,
                  displaySession: null,
                  items: const [],
                  isPrepWindow: false,
                );

            final categories = _buildCategories(resolvedState.items);
            if (!categories.contains(_selectedCategory)) {
              _selectedCategory = 'All Food';
            }
            final filteredItems = _filterItems(resolvedState.items);

            return Scaffold(
              backgroundColor: const Color(0xFFF4EFF7),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(settings.businessName),
                actions: [
                  StreamBuilder<AuthUser?>(
                    stream: _authController.watchAuthUser(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (user != null)
                            IconButton(
                              tooltip: 'Logout',
                              onPressed: _authController.signOut,
                              icon: const Icon(Icons.logout_rounded),
                            ),
                          PopupMenuButton<String>(
                            tooltip: user == null ? 'Sign in' : 'Account',
                            onSelected: _handleAccountSelection,
                            itemBuilder: (context) {
                              if (user == null) {
                                return const [
                                  PopupMenuItem<String>(
                                    value: 'sign_in',
                                    child: Text('Sign in'),
                                  ),
                                ];
                              }

                              return [
                                PopupMenuItem<String>(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'sign_out',
                                  child: Text('Sign out'),
                                ),
                              ];
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFFFFE5F0),
                                child: Icon(
                                  user == null
                                      ? Icons.login_rounded
                                      : Icons.person_rounded,
                                  color: const Color(0xFFE91E63),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  ValueListenableBuilder<List<CartLineItem>>(
                    valueListenable: _cartController.watchItems(),
                    builder: (context, items, _) {
                      final itemCount = items.fold<int>(
                        0,
                        (sum, entry) => sum + entry.quantity,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRoutes.cart),
                              icon: const Icon(Icons.shopping_bag_outlined),
                            ),
                            if (itemCount > 0)
                              Positioned(
                                right: 2,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$itemCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  children: [
                    _BusinessNoticeCard(settings: settings),
                    const SizedBox(height: 14),
                    _StatusCard(
                      title: resolvedState.activeSession != null
                          ? resolvedState.displaySession?.name ?? 'Menu'
                          : resolvedState.displaySession != null
                          ? 'Up next: ${resolvedState.displaySession!.name}'
                          : 'Kitchen schedule',
                      subtitle: _buildSubtitle(context, resolvedState),
                      isPrepWindow:
                          resolvedState.isPrepWindow || !settings.orderingOpen,
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<InAppNotification?>(
                      valueListenable: _notificationService.currentNotification,
                      builder: (context, notification, _) {
                        if (notification == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _NotificationBanner(
                            notification: notification,
                            onDismiss: _notificationService.clearNotification,
                            onTap: () {
                              final route = notification.route;
                              _notificationService.clearNotification();
                              if (route != null && route.isNotEmpty) {
                                Navigator.pushNamed(context, route);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SearchBar(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final selected = category == _selectedCategory;
                                return _CategoryChip(
                                  label: category,
                                  selected: selected,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (filteredItems.isEmpty)
                            _EmptyResultsCard(
                              message: resolvedState.displaySession == null
                                  ? 'The admin dashboard has not published any meal sessions yet.'
                                  : 'No menu items are live for this session yet.',
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredItems.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 14,
                                    mainAxisExtent: 274,
                                  ),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isFavorite = _favoriteItemIds.contains(
                                  item.id,
                                );
                                return _FoodCard(
                                  item: item,
                                  isFavorite: isFavorite,
                                  orderingEnabled:
                                      settings.orderingOpen &&
                                      resolvedState.activeSession != null,
                                  onFavoriteTap: () => _toggleFavorite(item.id),
                                  onTap: () => _showMenuDetails(
                                    item,
                                    settings: settings,
                                    state: resolvedState,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

const Map<String, double> _sizeMultipliers = <String, double>{
  'Small': 0.9,
  'Medium': 1.0,
  'Large': 1.2,
};

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.isPrepWindow,
  });

  final String title;
  final String subtitle;
  final bool isPrepWindow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrepWindow
              ? const [Color(0xFFFFE4C7), Color(0xFFFFC99A)]
              : const [Color(0xFFFFE2EF), Color(0xFFF7BBD5)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4C4050),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPrepWindow ? Icons.restaurant_menu_rounded : Icons.local_dining,
              color: const Color(0xFFE91E63),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessNoticeCard extends StatelessWidget {
  const _BusinessNoticeCard({required this.settings});

  final BusinessSettings settings;

  @override
  Widget build(BuildContext context) {
    final notices = <String>[
      if (settings.bannerMessage.trim().isNotEmpty)
        settings.bannerMessage.trim(),
      if (settings.activeOffer.trim().isNotEmpty)
        'Offer: ${settings.activeOffer.trim()}',
      if (settings.openingHoursNote.trim().isNotEmpty)
        settings.openingHoursNote.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.businessName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.orderingOpen
                          ? 'Ordering is live now'
                          : 'Ordering is currently paused',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6E5B67),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notices.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...notices.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  notice,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4C4050),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: settings.orderingOpen
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                label: settings.orderingOpen
                    ? 'Ordering open'
                    : 'Ordering paused',
              ),
              _MetaChip(
                icon: settings.pickupEnabled
                    ? Icons.store_mall_directory_rounded
                    : Icons.delivery_dining_rounded,
                label: settings.pickupEnabled ? 'Pickup enabled' : 'Pickup off',
              ),
              _MetaChip(icon: Icons.call_rounded, label: settings.phone),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE91E63)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  final InAppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2130),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFF78AB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE7DCE9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search favorite food',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF8F4FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE91E63) : const Color(0xFFF8F4FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF2D2432),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.item,
    required this.isFavorite,
    required this.orderingEnabled,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final MenuItem item;
  final bool isFavorite;
  final bool orderingEnabled;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFE91E63),
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Hero(
                  tag: 'menu-item-${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _FoodImage(item: item),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Color(0xFF8BC34A),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.prepTimeMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'KSh ${item.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: orderingEnabled
                          ? const Color(0xFFE91E63)
                          : const Color(0xFFF2C8D8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.item, this.fit = BoxFit.cover});

  final MenuItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (item.localImageAsset.trim().isNotEmpty) {
      return Image.asset(item.localImageAsset, fit: fit);
    }

    if (item.imageUrl.trim().isNotEmpty) {
      return Image.network(item.imageUrl, fit: fit);
    }

    return Container(
      color: const Color(0xFFF7F0EA),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 48, color: Color(0xFFE91E63)),
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE5F0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFE91E63) : const Color(0xFFE8E0D8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFE91E63) : const Color(0xFF2B242B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetQuantitySelector extends StatelessWidget {
  const _SheetQuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? onDecrement : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$quantity',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
