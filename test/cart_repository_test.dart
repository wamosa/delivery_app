import 'package:flutter_test/flutter_test.dart';

import 'package:ayeyo/features/cart/data/cart_repository.dart';
import 'package:ayeyo/features/menu/domain/menu_item.dart';

void main() {
  final item = MenuItem(
    id: 'item-1',
    name: 'Biryani',
    description: 'Spiced rice',
    price: 250,
    imageUrl: '',
    localImageAsset: '',
    categoryName: 'Meals',
    mealSessionId: 'lunch',
    isAvailable: true,
    stock: 10,
    prepTimeMinutes: 15,
  );

  group('CartRepository', () {
    setUp(() {
      CartRepository().clear();
    });

    test('adds items and computes totals', () {
      final repo = CartRepository();
      repo.addItem(item);
      repo.addItem(item);

      final summary = repo.getCartSummary(deliveryFee: 100);

      expect(summary.itemCount, 2);
      expect(summary.subtotal, 500);
      expect(summary.deliveryFee, 100);
      expect(summary.total, 600);
    });

    test('removes items when quantity is zero', () {
      final repo = CartRepository();
      repo.addItem(item);
      repo.updateQuantity(item.id, 0);

      expect(repo.items, isEmpty);
      final summary = repo.getCartSummary(deliveryFee: 100);
      expect(summary.total, 0);
    });
  });
}
