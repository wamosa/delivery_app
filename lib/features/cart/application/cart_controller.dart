import 'package:flutter/foundation.dart';

import '../../menu/domain/menu_item.dart';
import '../domain/cart_line_item.dart';
import '../data/cart_repository.dart';
import '../domain/cart_summary.dart';

class CartController {
  CartController({CartRepository? repository})
      : _repository = repository ?? CartRepository();

  final CartRepository _repository;

  ValueListenable<List<CartLineItem>> watchItems() => _repository.watchItems();

  List<CartLineItem> get items => _repository.items;

  void addItem(MenuItem item) => _repository.addItem(item);

  void updateQuantity(String itemId, int quantity) =>
      _repository.updateQuantity(itemId, quantity);

  void removeItem(String itemId) => _repository.removeItem(itemId);

  void clear() => _repository.clear();

  CartSummary loadSummary({double deliveryFee = 180}) =>
      _repository.getCartSummary(deliveryFee: deliveryFee);
}
