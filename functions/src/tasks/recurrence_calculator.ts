// functions/src/tasks/recurrence_calculator.ts
//
// Cálculo de la SIGUIENTE ocurrencia de una tarea recurrente, tz-aware.
//
// Réplica en backend de `lib/core/utils/recurrence_calculator.dart` (cliente):
// deriva la próxima fecha de la `RecurrenceRule` (hora/día/weekday/zona) en
// lugar de sumar intervalos en UTC, manteniendo la hora de pared estable a
// través de los cambios de horario de verano (DST). Hallazgo #10 del premortem.
//
// Motor de tiempo: luxon (usa la base IANA de la ICU del runtime, igual que el
// paquete `timezone` de Dart). Toda la aritmética de "hora de pared" se hace
// reconstruyendo el DateTime por componentes en la zona de la regla, igual que
// el cliente construye `tz.TZDateTime(location, y, m, d, h, m)`.

import { DateTime } from "luxon";

export type NormalizedRecurrenceRule =
  | { kind: "oneTime"; date: string; time: string; timezone: string }
  | { kind: "hourly"; every: number; startTime: string; endTime: string | null; timezone: string }
  | { kind: "daily"; every: number; time: string; timezone: string }
  | { kind: "weekly"; weekdays: string[]; time: string; timezone: string }
  | { kind: "monthlyFixed"; day: number; time: string; timezone: string }
  | { kind: "monthlyNth"; weekOfMonth: number; weekday: string; time: string; timezone: string }
  | { kind: "yearlyFixed"; month: number; day: number; time: string; timezone: string }
  | { kind: "yearlyNth"; month: number; weekOfMonth: number; weekday: string; time: string; timezone: string };

const WEEKDAY_TO_INT: Record<string, number> = {
  MON: 1,
  TUE: 2,
  WED: 3,
  THU: 4,
  FRI: 5,
  SAT: 6,
  SUN: 7,
};

// ── parser (paridad con TaskModel._ruleFromMap del cliente) ──────────────────

/**
 * Normaliza el map `recurrenceRule` de Firestore a una regla tipada.
 * Acepta el discriminante en `kind` (spec 2026-04-21) o en `type`, con los
 * mismos defaults que el cliente para tolerar documentos incompletos/legacy.
 */
export function parseRecurrenceRule(map: Record<string, unknown>): NormalizedRecurrenceRule {
  const m = map ?? {};
  const type = (m["kind"] as string | undefined) ?? (m["type"] as string | undefined) ?? "daily";
  const tz = (m["timezone"] as string | undefined) ?? "UTC";
  const time = (m["time"] as string | undefined) ?? "09:00";
  const asInt = (v: unknown, def: number): number =>
    typeof v === "number" ? v : def;

  switch (type) {
    case "oneTime":
      return {
        kind: "oneTime",
        date: (m["date"] as string | undefined) ?? "1970-01-01",
        time,
        timezone: tz,
      };
    case "hourly":
      return {
        kind: "hourly",
        every: asInt(m["every"], 1),
        startTime: (m["startTime"] as string | undefined) ?? "08:00",
        endTime: (m["endTime"] as string | undefined) ?? null,
        timezone: tz,
      };
    case "daily":
      return { kind: "daily", every: asInt(m["every"], 1), time, timezone: tz };
    case "weekly":
      return {
        kind: "weekly",
        weekdays: Array.isArray(m["weekdays"]) ? (m["weekdays"] as string[]) : ["MON"],
        time,
        timezone: tz,
      };
    case "monthlyFixed":
      return { kind: "monthlyFixed", day: asInt(m["day"], 1), time, timezone: tz };
    case "monthlyNth":
      return {
        kind: "monthlyNth",
        weekOfMonth: asInt(m["weekOfMonth"], 1),
        weekday: (m["weekday"] as string | undefined) ?? "MON",
        time,
        timezone: tz,
      };
    case "yearlyFixed":
      return {
        kind: "yearlyFixed",
        month: asInt(m["month"], 1),
        day: asInt(m["day"], 1),
        time,
        timezone: tz,
      };
    case "yearlyNth":
      return {
        kind: "yearlyNth",
        month: asInt(m["month"], 1),
        weekOfMonth: asInt(m["weekOfMonth"], 1),
        weekday: (m["weekday"] as string | undefined) ?? "MON",
        time,
        timezone: tz,
      };
    default:
      // Tipo desconocido → daily (mismo fallback que el cliente).
      return { kind: "daily", every: 1, time, timezone: tz };
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

function parseTime(time: string): { h: number; m: number } {
  const [h, m] = time.split(":");
  return { h: parseInt(h, 10), m: parseInt(m, 10) };
}

/** Días del mes (1-based) en aritmética de calendario pura (sin zona). */
function daysInMonth(year: number, month: number): number {
  return DateTime.utc(year, month, 1).daysInMonth ?? 31;
}

/** Weekday (1=Mon..7=Sun) de una fecha de calendario, independiente de zona. */
function calendarWeekday(year: number, month: number, day: number): number {
  return DateTime.utc(year, month, day).weekday;
}

/** Día del n-ésimo `weekday` (1..7) del mes; null si no existe (p. ej. 5.ª). */
function nthWeekdayOfMonth(
  year: number,
  month: number,
  n: number,
  weekday: number
): number | null {
  let count = 0;
  const last = daysInMonth(year, month);
  for (let day = 1; day <= last; day++) {
    if (calendarWeekday(year, month, day) === weekday) {
      count++;
      if (count === n) return day;
    }
  }
  return null;
}

/**
 * Construye el instante de una hora de pared concreta en `zone`.
 * Réplica de `tz.TZDateTime(location, y, mo, d, h, mi)`: si la hora local no
 * existe (gap del spring-forward), luxon avanza al siguiente instante válido.
 */
function wall(
  zone: string,
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number
): DateTime {
  return DateTime.fromObject(
    { year, month, day, hour, minute, second: 0, millisecond: 0 },
    { zone }
  );
}

/** Cota inferior: con `preferToday`, el inicio del día de `from` en la zona. */
function lowerBound(tzFrom: DateTime, preferToday: boolean): DateTime {
  if (!preferToday) return tzFrom;
  return tzFrom.startOf("day");
}

// ── cálculo de la siguiente ocurrencia ───────────────────────────────────────

/**
 * Próxima ocurrencia DESPUÉS de `from` según `rule`, en la zona de la regla.
 * Devuelve el instante absoluto (Date). Para `oneTime` devuelve el instante de
 * la regla. Con `preferToday` las reglas recurrentes aceptan la ocurrencia de
 * HOY aunque su hora ya haya pasado (soporte del checkbox "asignar también hoy"
 * en el cliente; el backend lo deja en false).
 */
export function nextDue(
  rule: NormalizedRecurrenceRule,
  from: Date,
  opts: { preferToday?: boolean } = {}
): Date {
  const preferToday = opts.preferToday ?? false;
  const zone = rule.timezone;

  switch (rule.kind) {
    case "oneTime": {
      const [y, mo, d] = rule.date.split("-").map((s) => parseInt(s, 10));
      const t = parseTime(rule.time);
      return wall(zone, y, mo, d, t.h, t.m).toJSDate();
    }
    case "hourly":
      return nextHourly(rule, from);
    case "daily":
      return nextDaily(rule, from, preferToday);
    case "weekly":
      return nextWeekly(rule, from, preferToday);
    case "monthlyFixed":
      return nextMonthlyFixed(rule, from, preferToday);
    case "monthlyNth":
      return nextMonthlyNth(rule, from, preferToday);
    case "yearlyFixed":
      return nextYearlyFixed(rule, from, preferToday);
    case "yearlyNth":
      return nextYearlyNth(rule, from, preferToday);
  }
}

function nextHourly(
  rule: Extract<NormalizedRecurrenceRule, { kind: "hourly" }>,
  from: Date
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  // Suma de duración real (igual que `tzFrom.add(Duration(hours:every))`).
  const candidate = tzFrom.plus({ hours: rule.every });

  if (rule.endTime) {
    const end = parseTime(rule.endTime);
    const start = parseTime(rule.startTime);
    const candidateMins = candidate.hour * 60 + candidate.minute;
    const endMins = end.h * 60 + end.m;
    if (candidateMins > endMins) {
      // Supera la ventana → día siguiente a la hora de inicio (misma zona).
      const nextDay = candidate.plus({ days: 1 });
      return wall(zone, nextDay.year, nextDay.month, nextDay.day, start.h, start.m).toJSDate();
    }
  }
  return candidate.toJSDate();
}

function nextDaily(
  rule: Extract<NormalizedRecurrenceRule, { kind: "daily" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);

  let candidate = wall(zone, tzFrom.year, tzFrom.month, tzFrom.day, t.h, t.m);
  while (candidate <= lower) {
    const next = candidate.plus({ days: rule.every });
    candidate = wall(zone, next.year, next.month, next.day, t.h, t.m);
  }
  return candidate.toJSDate();
}

function nextWeekly(
  rule: Extract<NormalizedRecurrenceRule, { kind: "weekly" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);
  const weekdayInts = new Set(rule.weekdays.map((w) => WEEKDAY_TO_INT[w]));

  // Esta semana (día 0..7 desde tzFrom).
  for (let i = 0; i < 8; i++) {
    const date = DateTime.utc(tzFrom.year, tzFrom.month, tzFrom.day).plus({ days: i });
    if (weekdayInts.has(date.weekday)) {
      const candidate = wall(zone, date.year, date.month, date.day, t.h, t.m);
      if (candidate > lower) return candidate.toJSDate();
    }
  }
  // Semana siguiente.
  const base = DateTime.utc(tzFrom.year, tzFrom.month, tzFrom.day).plus({ days: 7 });
  for (let i = 0; i < 7; i++) {
    const d = base.plus({ days: i });
    if (weekdayInts.has(d.weekday)) {
      const candidate = wall(zone, d.year, d.month, d.day, t.h, t.m);
      if (candidate > lower) return candidate.toJSDate();
    }
  }
  throw new Error(`No weekly occurrence found for weekdays=${rule.weekdays}`);
}

function nextMonthlyFixed(
  rule: Extract<NormalizedRecurrenceRule, { kind: "monthlyFixed" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);
  let year = tzFrom.year;
  let month = tzFrom.month;

  for (let i = 0; i < 13; i++) {
    const last = daysInMonth(year, month);
    const day = Math.min(Math.max(rule.day, 1), last);
    const candidate = wall(zone, year, month, day, t.h, t.m);
    if (candidate > lower) return candidate.toJSDate();
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
  throw new Error("No monthly fixed occurrence found");
}

function nextMonthlyNth(
  rule: Extract<NormalizedRecurrenceRule, { kind: "monthlyNth" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);
  const weekdayInt = WEEKDAY_TO_INT[rule.weekday];
  let year = tzFrom.year;
  let month = tzFrom.month;

  for (let i = 0; i < 13; i++) {
    const day = nthWeekdayOfMonth(year, month, rule.weekOfMonth, weekdayInt);
    if (day !== null) {
      const candidate = wall(zone, year, month, day, t.h, t.m);
      if (candidate > lower) return candidate.toJSDate();
    }
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
  throw new Error("No monthly Nth occurrence found");
}

function nextYearlyFixed(
  rule: Extract<NormalizedRecurrenceRule, { kind: "yearlyFixed" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);
  let year = tzFrom.year;

  for (let i = 0; i < 3; i++) {
    const last = daysInMonth(year, rule.month);
    const day = Math.min(Math.max(rule.day, 1), last);
    const candidate = wall(zone, year, rule.month, day, t.h, t.m);
    if (candidate > lower) return candidate.toJSDate();
    year++;
  }
  throw new Error("No yearly fixed occurrence found");
}

function nextYearlyNth(
  rule: Extract<NormalizedRecurrenceRule, { kind: "yearlyNth" }>,
  from: Date,
  preferToday: boolean
): Date {
  const zone = rule.timezone;
  const tzFrom = DateTime.fromJSDate(from, { zone });
  const t = parseTime(rule.time);
  const lower = lowerBound(tzFrom, preferToday);
  const weekdayInt = WEEKDAY_TO_INT[rule.weekday];
  let year = tzFrom.year;

  for (let i = 0; i < 3; i++) {
    const day = nthWeekdayOfMonth(year, rule.month, rule.weekOfMonth, weekdayInt);
    if (day !== null) {
      const candidate = wall(zone, year, rule.month, day, t.h, t.m);
      if (candidate > lower) return candidate.toJSDate();
    }
    year++;
  }
  throw new Error("No yearly Nth occurrence found");
}

// ── integración con el documento de tarea de Firestore ───────────────────────

/**
 * Calcula la siguiente `nextDueAt` de una tarea a partir de su `recurrenceRule`
 * tz-aware. Reemplaza a `addRecurrenceInterval`, que sumaba intervalos en UTC e
 * ignoraba la regla (Hallazgo #10).
 *
 * - `oneTime` es terminal: devuelve `currentDue` sin modificar (el caller marca
 *   la tarea como `completedOneTime`; conservamos la fecha para el historial).
 * - Si falta `recurrenceRule` (documentos legacy), se reconstruye una regla a
 *   partir de `recurrenceType` + la hora UTC de `currentDue`, reproduciendo el
 *   comportamiento anterior (suma de intervalo manteniendo la hora UTC). Las
 *   tareas creadas/editadas por el cliente siempre llevan `recurrenceRule`.
 */
export function computeNextDueAt(
  task: Record<string, unknown>,
  currentDue: Date
): Date {
  const recurrenceType = (task["recurrenceType"] as string | undefined) ?? "daily";
  if (recurrenceType === "oneTime") return currentDue;

  const ruleMap = task["recurrenceRule"] as Record<string, unknown> | undefined;
  if (ruleMap && typeof ruleMap === "object") {
    return nextDue(parseRecurrenceRule(ruleMap), currentDue);
  }
  // Fallback legacy: deriva una regla desde recurrenceType en UTC.
  return nextDue(legacyRuleFromType(recurrenceType, currentDue), currentDue);
}

/**
 * Construye una `RecurrenceRule` en UTC a partir del `recurrenceType` grueso y
 * la `currentDue`, para tareas legacy sin `recurrenceRule`. Replica el
 * comportamiento histórico (incremento de intervalo manteniendo la hora UTC).
 */
function legacyRuleFromType(recurrenceType: string, currentDue: Date): NormalizedRecurrenceRule {
  const d = DateTime.fromJSDate(currentDue, { zone: "UTC" });
  const time = `${String(d.hour).padStart(2, "0")}:${String(d.minute).padStart(2, "0")}`;
  switch (recurrenceType) {
    case "hourly":
      return { kind: "hourly", every: 1, startTime: time, endTime: null, timezone: "UTC" };
    case "weekly": {
      const names = ["", "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
      return { kind: "weekly", weekdays: [names[d.weekday]], time, timezone: "UTC" };
    }
    case "monthly":
      return { kind: "monthlyFixed", day: d.day, time, timezone: "UTC" };
    case "yearly":
      return { kind: "yearlyFixed", month: d.month, day: d.day, time, timezone: "UTC" };
    case "daily":
    default:
      return { kind: "daily", every: 1, time, timezone: "UTC" };
  }
}
