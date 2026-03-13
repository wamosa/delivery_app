import 'package:flutter/material.dart';

import '../../auth/domain/auth_user.dart';
import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.user,
    super.key,
  });

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final modules = HomeController().loadModules(user.role);

    return FeatureScaffold(
      title: 'Ayeyo Delivery',
      subtitle:
          'Signed in as ${user.name} (${user.role.label}). Your dashboard is filtered by role.',
      children: [
        InfoCard(
          title: 'Account summary',
          description:
              '${user.email} • ${user.role.label} access is active for this session.',
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
