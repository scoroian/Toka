import 'dart:ui' show Locale;

import '../../../core/utils/toka_dates.dart';
import 'home_dashboard.dart' show TaskPreview;

/// Lógica de actionability + formato de mensaje "vence el {fecha}" para
/// tareas. Compartida entre la skin v2 (`TodayTaskCardTodoV2`) y la skin
/// futurista (`TodayScreenFuturista`).
///
/// Pure-static: no estado, no providers, no dependencias UI más allá de
/// `Locale` (para `intl`). Testeable con `test()` puro sin widget tester.
class TaskActionability {
  TaskActionability._();

  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Reglas:
  /// - Tareas vencidas (due < now) son siempre actionable.
  /// - hourly: due cae en la hora actual.
  /// - daily: due cae hoy.
  /// - weekly: due cae en la semana actual lunes-domingo, calculada con
  ///   `DateTime.weekday` (NO cumple ISO 8601 estricto en fronteras de año).
  /// - monthly: due cae en el mes actual.
  /// - yearly: due cae en el año actual.
  /// - oneTime / desconocido: equivalente a daily.
  static bool isActionable(TaskPreview t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final due = t.nextDueAt;
    if (due.isBefore(n)) return true;
    switch (t.recurrenceType) {
      case 'hourly':
        return due.isBefore(DateTime(n.year, n.month, n.day, n.hour + 1));
      case 'daily':
        return due.isBefore(DateTime(n.year, n.month, n.day + 1));
      case 'weekly':
        final daysFromMonday = n.weekday - 1;
        final weekStart = DateTime(n.year, n.month, n.day - daysFromMonday);
        return due.isBefore(weekStart.add(const Duration(days: 7)));
      case 'monthly':
        return due.isBefore(DateTime(n.year, n.month + 1, 1));
      case 'yearly':
        return due.isBefore(DateTime(n.year + 1, 1, 1));
      default:
        return due.isBefore(DateTime(n.year, n.month, n.day + 1));
    }
  }

  /// Formato del mensaje "vence el {fecha}" según el tipo de recurrencia.
  /// Devuelve la cadena que se inyecta en `l10n.today_hecho_not_yet(date)`.
  static String formatDueForMessage(TaskPreview t, Locale locale) {
    final due = t.nextDueAt.toLocal();
    switch (t.recurrenceType) {
      case 'hourly':
        return TokaDates.timeShort(due, locale);
      case 'daily':
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
      case 'weekly':
        return TokaDates.dateMediumWithWeekday(due, locale);
      case 'monthly':
        return TokaDates.dateLongDayMonth(due, locale);
      case 'yearly':
        return TokaDates.monthYearLong(due, locale);
      default:
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
    }
  }
}
