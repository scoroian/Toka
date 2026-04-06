import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class TodayTaskCardTodo extends StatelessWidget {
  final TaskPreview task;
  final String? currentUid;
  final VoidCallback? onDone;
  final VoidCallback? onPass;

  /// Inyectable para tests — por defecto DateTime.now()
  final DateTime? now;

  const TodayTaskCardTodo({
    super.key,
    required this.task,
    required this.currentUid,
    this.onDone,
    this.onPass,
    this.now,
  });

  String _dueDateLabel(BuildContext context, AppLocalizations l10n) {
    if (task.isOverdue) return l10n.today_overdue;
    final effectiveNow = now ?? DateTime.now();
    final dueDate = task.nextDueAt;
    final timeStr = DateFormat('HH:mm').format(dueDate);
    final isToday = dueDate.year == effectiveNow.year &&
        dueDate.month == effectiveNow.month &&
        dueDate.day == effectiveNow.day;
    if (isToday) return l10n.today_due_today(timeStr);
    final weekday = DateFormat(
      'EEE',
      Localizations.localeOf(context).toString(),
    ).format(dueDate);
    return l10n.today_due_weekday(weekday, timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAssignedToMe =
        task.currentAssigneeUid != null &&
        task.currentAssigneeUid == currentUid;
    final dueLabel = _dueDateLabel(context, l10n);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AssigneeAvatar(
                  name: task.currentAssigneeName,
                  photoUrl: task.currentAssigneePhoto,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${task.visualValue} ${task.title}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _DueDateChip(
                  label: dueLabel,
                  isOverdue: task.isOverdue,
                ),
              ],
            ),
            if (isAssignedToMe) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    key: const Key('btn_done'),
                    onPressed: onDone ?? () {},
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.today_btn_done),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('btn_pass'),
                    onPressed: onPass ?? () {},
                    icon: const Icon(Icons.sync, size: 16),
                    label: Text(l10n.today_btn_pass),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;

  const _AssigneeAvatar({this.name, this.photoUrl});

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.secondary,
      child: Text(
        _initials,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final String label;
  final bool isOverdue;

  const _DueDateChip({required this.label, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isOverdue ? AppColors.error : AppColors.textSecondary,
          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
