import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuthController();

    return FutureBuilder<AuthUser>(
      future: controller.loadUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return FeatureScaffold(
          title: 'Authentication',
          subtitle: 'Identity, sign in, and access rules live in auth.',
          children: [
            InfoCard(
              title: 'Current user',
              description: user == null
                  ? 'Loading signed-in user...'
                  : '${user.name} • ${user.email} • ${user.phone} • ${user.role}',
            ),
            const InfoCard(
              title: 'Why this layer exists',
              description:
                  'Presentation renders forms, application coordinates login flow, domain defines user concepts, and data talks to Firebase Auth.',
            ),
          ],
        );
      },
    );
  }
}
