import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formateadores de fecha y hora centralizados para Toka.
///
/// Todos los helpers reciben el [Locale] explícito. En widgets usa
/// `Localizations.localeOf(context)`. Fuera de un `BuildContext`
/// (servicios, view-models) construye el locale desde `l10n.localeName`
/// (`Locale(l10n.localeName)`).
///
/// Horas en 24h en los 3 locales soportados (es/en/ro) para mantener
/// consistencia interna (ver BUG-15 en la sesión QA 2026-04-20).
class TokaDates {
  const TokaDates._();

  /// "09:30" — siempre HH:mm (24h, con cero a la izquierda).
  static String timeShort(DateTime dt, Locale locale) =>
      DateFormat('HH:mm', locale.toString()).format(dt);

  /// "vie 25 abr" / "Fri 25 Apr" / "vin. 25 apr."
  static String dateMediumWithWeekday(DateTime dt, Locale locale) =>
      DateFormat('EEE d MMM', locale.toString()).format(dt);

  /// "25 de abril" / "April 25" / "25 aprilie"
  static String dateLongDayMonth(DateTime dt, Locale locale) =>
      DateFormat('d MMMM', locale.toString()).format(dt);

  /// "25 de abril de 2026"
  static String dateLongFull(DateTime dt, Locale locale) =>
      DateFormat('d MMMM y', locale.toString()).format(dt);

  /// "25/4/2026" (es/ro) — "4/25/2026" (en)
  static String dateShort(DateTime dt, Locale locale) =>
      DateFormat.yMd(locale.toString()).format(dt);

  /// "25/4/2026 — 09:30"
  static String dateTimeShort(DateTime dt, Locale locale) =>
      '${dateShort(dt, locale)} — ${timeShort(dt, locale)}';

  /// "abril de 2026" / "April 2026" / "aprilie 2026"
  static String monthYearLong(DateTime dt, Locale locale) =>
      DateFormat.yMMMM(locale.toString()).format(dt);

  /// "vie" / "Fri" / "vin."
  static String weekdayShort(DateTime dt, Locale locale) =>
      DateFormat('EEE', locale.toString()).format(dt);

  /// "25 abr 09:30" — útil para cards compactas.
  static String dayMonthTimeShort(DateTime dt, Locale locale) =>
      '${DateFormat.MMMd(locale.toString()).format(dt)} '
      '${timeShort(dt, locale)}';
}
