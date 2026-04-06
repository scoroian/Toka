import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class TodayTaskCardDone extends StatelessWidget {
  final DoneTaskPreview task;

  const TodayTaskCardDone({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeStr = DateFormat('HH:mm').format(task.completedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppColors.surface.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.visualValue} ${task.title}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textSecondary,
                          color: AppColors.textSecondary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.today_done_by(task.completedByName, timeStr),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    key: const Key('done_by_label'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
