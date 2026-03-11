import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/menu_controller.dart' as menu_feature;
import '../domain/menu_item.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = menu_feature.MenuController();

    return FutureBuilder<List<MenuItem>>(
      future: controller.loadPopularItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <MenuItem>[];
        return FeatureScaffold(
          title: 'Menu',
          subtitle:
              'Restaurant listings, categories, search, and item details should stay inside this feature.',
          children: items
              .map(
                (item) => InfoCard(
                  title: item.name,
                  description:
                      'KSh ${item.price.toStringAsFixed(0)} • Stock ${item.stock} • Prep ${item.prepTimeMinutes} min',
                ),
              )
              .toList(),
        );
      },
    );
  }
}
