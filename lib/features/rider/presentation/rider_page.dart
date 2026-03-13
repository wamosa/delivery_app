import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';

class RiderPage extends StatelessWidget {
  const RiderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureScaffold(
      title: 'Rider Dashboard',
      subtitle:
          'Pick up assigned orders, update delivery progress, and confirm drop-offs.',
      children: [
        InfoCard(
          title: 'Assigned pickups',
          description:
              'See which restaurants to visit next and the customer orders ready for delivery.',
        ),
        InfoCard(
          title: 'Delivery updates',
          description:
              'Move orders through picked up, on the way, and delivered states.',
        ),
      ],
    );
  }
}
