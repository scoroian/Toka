import 'package:flutter/material.dart';

import '../../domain/user_profile.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.profile,
    required this.totalCompleted,
    required this.globalCompliance,
  });

  final UserProfile profile;
  final int totalCompleted;
  final double globalCompliance;

  @override
  Widget build(BuildContext context) {
    final compliancePct = (globalCompliance * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(
            key: const Key('stat_total_completed'),
            label: 'Tareas completadas',
            value: totalCompleted.toString()),
        _StatRow(
            key: const Key('stat_global_compliance'),
            label: 'Cumplimiento global',
            value: '$compliancePct%'),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
