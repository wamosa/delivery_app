import '../../menu/domain/menu_item.dart';

class CartLineItem {
  const CartLineItem({
    required this.item,
    required this.quantity,
  });

  final MenuItem item;
  final int quantity;

  double get lineTotal => item.price * quantity;

  CartLineItem copyWith({
    MenuItem? item,
    int? quantity,
  }) {
    return CartLineItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
