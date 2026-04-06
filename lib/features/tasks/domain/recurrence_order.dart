import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

abstract class RecurrenceOrder {
  static const List<String> all = [
    'hourly',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static String localizedTitle(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      'hourly' => l10n.recurrenceHourly,
      'daily' => l10n.recurrenceDaily,
      'weekly' => l10n.recurrenceWeekly,
      'monthly' => l10n.recurrenceMonthly,
      'yearly' => l10n.recurrenceYearly,
      _ => type,
    };
  }
}
