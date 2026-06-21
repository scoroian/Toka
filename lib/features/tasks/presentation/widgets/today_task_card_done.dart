import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';
import '../utils/task_visual_utils.dart';

class TodayTaskCardDone extends StatelessWidget {
  final DoneTaskPreview task;

  const TodayTaskCardDone({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeStr = TokaDates.timeShort(
        task.completedAt.toLocal(), Localizations.localeOf(context));

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
                  Row(
                    children: [
                      // Renderiza emoji o icono Material (icon:<codepoint>).
                      // Antes se concatenaba `visualValue` como texto, lo que
                      // mostraba el codepoint crudo (p.ej. "57622") en iconos.
                      taskVisualWidget(task.visualKind, task.visualValue,
                          size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.textSecondary,
                                    color: AppColors.textSecondary,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
