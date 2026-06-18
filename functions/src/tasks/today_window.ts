// functions/src/tasks/today_window.ts
//
// Cálculo del "día de hoy" del hogar para el dashboard. La definición de "hoy"
// (y por tanto de qué tareas vencen hoy / están vencidas) se hace SIEMPRE en la
// zona horaria del hogar, no en la del proceso (Cloud Functions corre en UTC) ni
// en la del dispositivo. Así el contador `tasksDueToday` coincide con lo que ven
// todos los miembros y no depende de la zona del servidor.
//
// Implementación sin dependencias externas: Node 20 trae ICU completo, así que
// `Intl.DateTimeFormat` con `timeZone` resuelve correctamente DST y offsets.

export const DEFAULT_HOME_TIMEZONE = "Europe/Madrid";

export type DueBucket = "overdue" | "today" | "future";

export interface DayBounds {
  /** Instante UTC del inicio (00:00 local) del día actual en la zona. */
  start: Date;
  /** Instante UTC del inicio del día siguiente (fin exclusivo del día actual). */
  end: Date;
}

function isValidTimeZone(timeZone: string | undefined): timeZone is string {
  if (!timeZone) return false;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone });
    return true;
  } catch {
    return false;
  }
}

/** Devuelve `timeZone` si es una zona IANA válida; si no, [DEFAULT_HOME_TIMEZONE]. */
export function normalizeTimeZone(timeZone: string | undefined): string {
  return isValidTimeZone(timeZone) ? timeZone : DEFAULT_HOME_TIMEZONE;
}

interface WallParts {
  year: number;
  month: number; // 1-12
  day: number;
  hour: number; // 0-23
  minute: number;
  second: number;
}

/** Descompone un instante en sus componentes de reloj de pared en `timeZone`. */
function wallParts(instant: Date, timeZone: string): WallParts {
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  const out: Record<string, number> = {};
  for (const p of dtf.formatToParts(instant)) {
    if (p.type !== "literal") out[p.type] = parseInt(p.value, 10);
  }
  return {
    year: out["year"],
    month: out["month"],
    day: out["day"],
    hour: out["hour"],
    minute: out["minute"],
    second: out["second"],
  };
}

/**
 * Offset de `timeZone` en milisegundos para un instante dado, definido como
 * (reloj de pared reinterpretado como UTC) − instante. P. ej. Madrid en verano
 * devuelve +7200000 (UTC+2).
 */
function tzOffsetMs(instant: Date, timeZone: string): number {
  const w = wallParts(instant, timeZone);
  const asUtc = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, w.second);
  return asUtc - instant.getTime();
}

/**
 * Instante UTC cuyo reloj de pared en `timeZone` es exactamente
 * `year-month-day 00:00:00`. Refina una vez el offset para ser robusto en los
 * días de cambio de horario (DST).
 */
function localMidnightUtc(
  year: number,
  month: number,
  day: number,
  timeZone: string
): Date {
  const wallAsUtc = Date.UTC(year, month - 1, day, 0, 0, 0);
  let offset = tzOffsetMs(new Date(wallAsUtc), timeZone);
  let t = wallAsUtc - offset;
  offset = tzOffsetMs(new Date(t), timeZone);
  t = wallAsUtc - offset;
  return new Date(t);
}

/**
 * Devuelve los instantes UTC que delimitan el día natural actual (según `now`)
 * en la zona horaria `timeZone`. Si la zona es inválida cae a
 * [DEFAULT_HOME_TIMEZONE].
 */
export function localDayBoundsUtc(now: Date, timeZone: string): DayBounds {
  const tz = isValidTimeZone(timeZone) ? timeZone : DEFAULT_HOME_TIMEZONE;
  const today = wallParts(now, tz);
  const start = localMidnightUtc(today.year, today.month, today.day, tz);
  // Día siguiente: normalizamos el desbordamiento de día/mes con Date.UTC.
  const nextWall = new Date(Date.UTC(today.year, today.month - 1, today.day + 1));
  const end = localMidnightUtc(
    nextWall.getUTCFullYear(),
    nextWall.getUTCMonth() + 1,
    nextWall.getUTCDate(),
    tz
  );
  return { start, end };
}

/**
 * Clasifica un instante de vencimiento respecto al día actual del hogar:
 * - "overdue": antes del inicio del día.
 * - "today":   dentro de [start, end).
 * - "future":  en el día siguiente o posterior.
 */
export function classifyDue(nextDueAt: Date, bounds: DayBounds): DueBucket {
  const t = nextDueAt.getTime();
  if (t < bounds.start.getTime()) return "overdue";
  if (t < bounds.end.getTime()) return "today";
  return "future";
}

export interface DueSummary {
  /** Límites del día actual del hogar usados para clasificar. */
  bounds: DayBounds;
  /** Tareas cuyo vencimiento cae HOY (estricto). Es el valor de tasksDueToday. */
  dueTodayCount: number;
  /** Tareas accionables hoy = vencidas + las de hoy. Base de hasPendingToday. */
  pendingTodayCount: number;
}

/**
 * Resume una lista de instantes de vencimiento respecto al día actual del hogar.
 * `now` y `timeZone` se pasan por parámetro para poder testear con fechas fijas.
 */
export function summarizeDue(
  nextDueAts: Date[],
  now: Date,
  timeZone: string
): DueSummary {
  const bounds = localDayBoundsUtc(now, timeZone);
  let dueTodayCount = 0;
  let pendingTodayCount = 0;
  for (const due of nextDueAts) {
    const bucket = classifyDue(due, bounds);
    if (bucket === "today") {
      dueTodayCount++;
      pendingTodayCount++;
    } else if (bucket === "overdue") {
      pendingTodayCount++;
    }
  }
  return { bounds, dueTodayCount, pendingTodayCount };
}
