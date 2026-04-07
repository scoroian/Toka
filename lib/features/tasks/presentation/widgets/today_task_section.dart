import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';
import '../../domain/recurrence_order.dart';
import 'today_task_card_done.dart';
import 'today_task_card_todo.dart';

class TodayTaskSection extends StatelessWidget {
  final String recurrenceType;
  final List<TaskPreview> todos;
  final List<DoneTaskPreview> dones;
  final String? currentUid;
  final void Function(TaskPreview)? onDone;
  final void Function(TaskPreview)? onPass;

  const TodayTaskSection({
    super.key,
    required this.recurrenceType,
    required this.todos,
    required this.dones,
    required this.currentUid,
    this.onDone,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionTitle = RecurrenceOrder.localizedTitle(context, recurrenceType);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              key: Key('section_title_$recurrenceType'),
            ),
          ),
        ),
        if (todos.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                l10n.today_section_todo,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final task = todos[index];
              return TodayTaskCardTodo(
                task: task,
                currentUid: currentUid,
                onDone: onDone != null ? () => onDone!(task) : null,
                onPass: onPass != null ? () => onPass!(task) : null,
              );
            },
          ),
        ],
        if (dones.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Text(
                l10n.today_section_done,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: dones.length,
            itemBuilder: (context, index) =>
                TodayTaskCardDone(task: dones[index]),
          ),
        ],
      ],
    );
  }
}
