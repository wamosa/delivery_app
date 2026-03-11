import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryName,
    required this.mealSessionId,
    required this.isAvailable,
    required this.stock,
    required this.prepTimeMinutes,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryName;
  final String mealSessionId;
  final bool isAvailable;
  final int stock;
  final int prepTimeMinutes;

  factory MenuItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MenuItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? 'General',
      mealSessionId: data['mealSessionId'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? false,
      stock: data['stock'] as int? ?? 0,
      prepTimeMinutes: data['prepTimeMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryName': categoryName,
      'mealSessionId': mealSessionId,
      'isAvailable': isAvailable,
      'stock': stock,
      'prepTimeMinutes': prepTimeMinutes,
    };
  }
}
