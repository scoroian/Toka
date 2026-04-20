import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../utils/task_visual_utils.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFrozen = task.status == TaskStatus.frozen;
    final dateStr = DateFormat.MMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(task.nextDueAt);

    // Suppress unused warning
    // ignore: unused_local_variable
    final _ = l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFrozen
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _VisualWidget(kind: task.visualKind, value: task.visualValue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: isFrozen
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: task.nextDueAt.isBefore(DateTime.now())
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (isFrozen)
                Icon(Icons.ac_unit,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualWidget extends StatelessWidget {
  const _VisualWidget({required this.kind, required this.value});
  final String kind;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: taskVisualWidget(kind, value, size: 24),
      ),
    );
  }
}
