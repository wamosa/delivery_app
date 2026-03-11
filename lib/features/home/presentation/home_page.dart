import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = HomeController().loadModules();

    return FeatureScaffold(
      title: 'Ayeyo Delivery',
      subtitle:
          'This home feature becomes the entry point for customers, riders, and admins depending on role.',
      children: [
        const InfoCard(
          title: 'Structure in practice',
          description:
              'Each feature owns its UI, use cases, business rules, and repositories so the codebase can grow without one giant folder.',
        ),
        ...modules.map(
          (module) => InfoCard(
            title: module.title,
            description: module.description,
            trailing: FilledButton(
              onPressed: () => Navigator.pushNamed(context, module.route),
              child: const Text('Open'),
            ),
          ),
        ),
      ],
    );
  }
}
