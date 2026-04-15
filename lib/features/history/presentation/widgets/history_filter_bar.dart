// lib/features/history/presentation/widgets/history_filter_bar.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/history_filter.dart';

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final HistoryFilter current;
  final void Function(HistoryFilter) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const Key('history_filter_bar'),
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            key: const Key('filter_chip_all'),
            label: Text(l10n.history_filter_all),
            selected: current.eventType == null,
            onSelected: (_) => onChanged(
              HistoryFilter(
                  memberUid: current.memberUid,
                  taskId: current.taskId),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_completed'),
            label: Text(l10n.history_filter_completed),
            selected: current.eventType == 'completed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'completed',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_passed'),
            label: Text(l10n.history_filter_passed),
            selected: current.eventType == 'passed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'passed',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_missed'),
            label: Text(l10n.history_filter_missed),
            selected: current.eventType == 'missed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'missed',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
