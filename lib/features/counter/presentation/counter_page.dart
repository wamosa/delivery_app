import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: 'Counter Dashboard',
      subtitle:
          'Receive new orders, confirm payment, coordinate preparation, and roll orders out for pickup.',
      children: [
        InfoCard(
          title: 'Incoming orders',
          description:
              'Review paid orders as they arrive and push them into the kitchen workflow.',
        ),
        InfoCard(
          title: 'Handover ready',
          description:
              'Mark packed orders as ready for pickup so riders and customers can be notified.',
        ),
      ],
    );
  }
}
