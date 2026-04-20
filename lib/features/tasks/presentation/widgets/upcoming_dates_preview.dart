import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/create_edit_task_view_model.dart';

class UpcomingDatesPreview extends StatelessWidget {
  const UpcomingDatesPreview({super.key, required this.dates});

  final List<UpcomingDateItem> dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (dates.isEmpty) return const SizedBox.shrink();

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
            title: Text(DateFormat.yMMMd().add_Hm().format(item.date)),
            subtitle: item.assigneeName != null
                ? Text(l10n.tasks_upcoming_preview_assignee(item.assigneeName!))
                : null,
          ),
        ),
      ],
    );
  }
}
