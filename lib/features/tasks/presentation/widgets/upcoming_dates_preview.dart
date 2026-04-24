import 'package:flutter/material.dart';

import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/create_edit_task_view_model.dart';
import '../../domain/recurrence_rule.dart';

class UpcomingDatesPreview extends StatelessWidget {
  const UpcomingDatesPreview({
    super.key,
    required this.dates,
    this.recurrenceRule,
  });

  final List<UpcomingDateItem> dates;

  /// Regla de recurrencia de la tarea para decidir el formato de fecha.
  /// Si es anual ([YearlyFixedRule] o [YearlyNthRule]), se incluye el año
  /// (BUG-23). Si es null o cualquier otra, se usa el formato medio sin año.
  final RecurrenceRule? recurrenceRule;

  bool get _isAnnual => switch (recurrenceRule) {
        YearlyFixedRule() || YearlyNthRule() => true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (dates.isEmpty) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context);

    String formatDate(DateTime d) => _isAnnual
        ? TokaDates.dateLongFull(d, locale)
        : TokaDates.dateMediumWithWeekday(d, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_upcoming_preview_title,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...dates.map(
          (item) => ListTile(
            key: Key('upcoming_date_${item.date.millisecondsSinceEpoch}'),
            dense: true,
            leading: const Icon(Icons.calendar_today, size: 18),
            title: Text(
              '${formatDate(item.date)} · '
              '${TokaDates.timeShort(item.date, locale)}',
            ),
            subtitle: item.assigneeName != null
                ? Text(l10n.tasks_upcoming_preview_assignee(item.assigneeName!))
                : null,
          ),
        ),
      ],
    );
  }
}
