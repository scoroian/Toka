// lib/features/subscription/application/days_left.dart
//
// Cálculo preciso de días restantes hasta una fecha. El backend guarda
// un `rescueFlags.daysLeft` que puede estar desfasado varias horas respecto
// al momento actual (el cron sólo corre 1×/día). El cliente prefiere este
// helper para recalcular en tiempo real sobre el `premiumEndsAt` absoluto.
//
// Regla: ceil (no floor). Si quedan 2.9 días, mostrar 3. Si queda <1h,
// mostrar 0 (y dejar que la UI cambie a un copy de horas).

library;

/// Días restantes entre [now] y [endsAt], redondeando hacia arriba.
///
/// - Si [endsAt] ya pasó → 0.
/// - Si quedan entre 1 y 60 minutos → 1 (nunca 0 mientras quede tiempo).
/// - Si quedan 23h59 → 1.
/// - Si quedan 24h01 → 2.
///
/// Nota: la entrada [now] es inyectable para tests.
int daysLeftFrom(DateTime endsAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = endsAt.difference(current);
  if (diff.inMinutes <= 0) return 0;
  return (diff.inMinutes / (60 * 24)).ceil();
}

/// Horas restantes (ceil) entre [now] y [endsAt]. Útil cuando queda menos
/// de un día y la UI debe decir "Quedan 7 horas".
int hoursLeftFrom(DateTime endsAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = endsAt.difference(current);
  if (diff.inMinutes <= 0) return 0;
  return (diff.inMinutes / 60).ceil();
}
