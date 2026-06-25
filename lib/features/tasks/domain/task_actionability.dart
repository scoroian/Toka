import 'dart:ui' show Locale;

import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/toka_dates.dart';
import 'home_dashboard.dart' show TaskPreview;

/// Lógica de actionability + formato de mensaje "vence el {fecha}" para
/// tareas. Usada por la skin v2 (`TodayTaskCardTodoV2`) y reutilizable por
/// cualquier skin futura.
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
  ///
  /// Las fronteras de "hoy/esta semana/este mes" se calculan en [timezone] (la
  /// zona del HOGAR, IANA), de modo que la sección en la que cae la tarea ("Por
  /// hacer" vs "Próximas") coincida con el label de hora —que también usa la
  /// zona del hogar— aunque el dispositivo esté en otra zona (Hallazgo #2-QA).
  /// Si [timezone] es null/vacío/desconocido se usa la zona del dispositivo,
  /// preservando el comportamiento previo.
  static bool isActionable(TaskPreview t, {DateTime? now, String? timezone}) {
    final nowRaw = now ?? DateTime.now();
    tz.Location? loc;
    if (timezone != null && timezone.isNotEmpty) {
      try {
        loc = tz.getLocation(timezone);
      } catch (_) {
        loc = null;
      }
    }
    // Con zona del hogar: due y now se expresan como TZDateTime en esa zona y
    // las fronteras se construyen ahí. Sin zona: se conserva el cálculo previo
    // en la zona del dispositivo (componentes de los DateTime tal cual).
    final due = loc != null ? tz.TZDateTime.from(t.nextDueAt, loc) : t.nextDueAt;
    final n = loc != null ? tz.TZDateTime.from(nowRaw, loc) : nowRaw;
    DateTime mk(int y, int mo, int d, [int h = 0]) =>
        loc != null ? tz.TZDateTime(loc, y, mo, d, h) : DateTime(y, mo, d, h);

    if (due.isBefore(n)) return true;
    switch (t.recurrenceType) {
      case 'hourly':
        return due.isBefore(mk(n.year, n.month, n.day, n.hour + 1));
      case 'daily':
        return due.isBefore(mk(n.year, n.month, n.day + 1));
      case 'weekly':
        final daysFromMonday = n.weekday - 1;
        final weekStart = mk(n.year, n.month, n.day - daysFromMonday);
        return due.isBefore(weekStart.add(const Duration(days: 7)));
      case 'monthly':
        return due.isBefore(mk(n.year, n.month + 1, 1));
      case 'yearly':
        return due.isBefore(mk(n.year + 1, 1, 1));
      default:
        return due.isBefore(mk(n.year, n.month, n.day + 1));
    }
  }

  /// Formato del mensaje "vence el {fecha}" según el tipo de recurrencia.
  /// Devuelve la cadena que se inyecta en `l10n.today_hecho_not_yet(date)`.
  /// [timezone] es la zona del hogar (Hallazgo #2-QA); si es null se usa la del
  /// dispositivo.
  static String formatDueForMessage(TaskPreview t, Locale locale,
      {String? timezone}) {
    final due = TokaDates.inZone(t.nextDueAt, timezone);
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
