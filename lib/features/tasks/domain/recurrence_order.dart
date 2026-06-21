import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

abstract class RecurrenceOrder {
  // 'oneTime' va primero: una tarea Puntual tiene fecha/hora concreta y es un
  // evento único, por lo que debe destacar arriba. Sin esta entrada las tareas
  // oneTime se agrupaban correctamente pero NUNCA se renderizaban en Hoy (el
  // bucle de la pantalla itera exactamente sobre esta lista).
  static const List<String> all = [
    'oneTime',
    'hourly',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static String localizedTitle(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      'oneTime' => l10n.recurrenceOneTime,
      'hourly' => l10n.recurrenceHourly,
      'daily' => l10n.recurrenceDaily,
      'weekly' => l10n.recurrenceWeekly,
      'monthly' => l10n.recurrenceMonthly,
      'yearly' => l10n.recurrenceYearly,
      _ => type,
    };
  }
}
