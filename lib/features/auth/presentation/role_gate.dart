import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/di/service_locator.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'auth_page.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({
    required this.allowedRoles,
    required this.child,
    super.key,
  });

  final List<AuthRole> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = getIt<AuthController>();

    return StreamBuilder<AuthUser?>(
      stream: controller.watchAuthUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthPage();
        }

        if (!allowedRoles.contains(user.role)) {
          return FeatureScaffold(
            title: 'Access denied',
            subtitle: 'Your account role does not have permission for this area.',
            showThemeToggle: false,
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: const Text('Permission needed'),
                  subtitle: Text(
                    'Signed in as ${user.role.label}. Ask an admin to grant access if you should use this screen.',
                  ),
                ),
              ),
            ],
          );
        }

        return child;
      },
    );
  }
}
