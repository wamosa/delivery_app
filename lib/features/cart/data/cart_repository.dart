import 'package:flutter/foundation.dart';

import '../../menu/domain/menu_item.dart';
import '../domain/cart_line_item.dart';
import '../domain/cart_summary.dart';

class CartRepository {
  factory CartRepository() => _instance;

  CartRepository._internal();

  static final CartRepository _instance = CartRepository._internal();

  final ValueNotifier<List<CartLineItem>> _items =
      ValueNotifier<List<CartLineItem>>(const []);

  ValueListenable<List<CartLineItem>> watchItems() => _items;

  List<CartLineItem> get items => List<CartLineItem>.unmodifiable(_items.value);

  void addItem(MenuItem item) {
    final nextItems = [..._items.value];
    final index = nextItems.indexWhere((entry) => entry.item.id == item.id);

    if (index == -1) {
      nextItems.add(CartLineItem(item: item, quantity: 1));
    } else {
      final current = nextItems[index];
      nextItems[index] = current.copyWith(quantity: current.quantity + 1);
    }

    _items.value = nextItems;
  }

  void updateQuantity(String itemId, int quantity) {
    final nextItems = [..._items.value];
    final index = nextItems.indexWhere((entry) => entry.item.id == itemId);
    if (index == -1) {
      return;
    }

    if (quantity <= 0) {
      nextItems.removeAt(index);
    } else {
      nextItems[index] = nextItems[index].copyWith(quantity: quantity);
    }

    _items.value = nextItems;
  }

  void removeItem(String itemId) {
    _items.value =
        _items.value.where((entry) => entry.item.id != itemId).toList();
  }

  void clear() {
    _items.value = const [];
  }

  CartSummary getCartSummary({double deliveryFee = 180}) {
    final subtotal = _items.value.fold<double>(
      0,
      (sum, entry) => sum + entry.lineTotal,
    );

    return CartSummary(
      itemCount: _items.value.fold<int>(
        0,
        (sum, entry) => sum + entry.quantity,
      ),
      subtotal: subtotal,
      deliveryFee: subtotal == 0 ? 0 : deliveryFee,
      total: subtotal == 0 ? 0 : subtotal + deliveryFee,
    );
  }
}
