import 'package:flutter/material.dart';

import '../../../core/widgets/feature_scaffold.dart';
import '../../../core/widgets/info_card.dart';
import '../application/admin_controller.dart';
import '../domain/admin_metric.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminController();

    return FutureBuilder<List<AdminMetric>>(
      future: controller.loadMetrics(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? const <AdminMetric>[];
        return FeatureScaffold(
          title: 'Admin',
          subtitle:
              'Operations dashboards, restaurant approvals, dispatch controls, and reporting can evolve here.',
          children: metrics
              .map(
                (metric) => InfoCard(
                  title: metric.label,
                  description: metric.value,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
