import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isCompact = Breakpoints.isCompact(context);
    final hasTrailing = trailing != null;

    if (isCompact && hasTrailing) {
      return Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: trailing,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(description),
        ),
        trailing: trailing,
      ),
    );
  }
}
