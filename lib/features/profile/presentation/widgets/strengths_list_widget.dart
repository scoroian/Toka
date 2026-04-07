// lib/features/profile/presentation/widgets/strengths_list_widget.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'radar_chart_widget.dart';

class StrengthsListWidget extends StatelessWidget {
  const StrengthsListWidget({super.key, required this.entries});

  final List<RadarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.radar_other_tasks,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...entries.map(
          (e) => ListTile(
            dense: true,
            title: Text(e.taskName),
            trailing: Text(
              e.avgScore.toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
