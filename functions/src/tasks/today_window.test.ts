// functions/src/tasks/today_window.test.ts
import {
  localDayBoundsUtc,
  classifyDue,
  summarizeDue,
  normalizeTimeZone,
  DEFAULT_HOME_TIMEZONE,
} from "./today_window";

describe("localDayBoundsUtc", () => {
  it("usa horario de verano en Europe/Madrid (+02:00)", () => {
    // 2026-06-16 22:00 Madrid (= 20:00Z). El día local Madrid es
    // [2026-06-16 00:00, 2026-06-17 00:00) → [2026-06-15 22:00Z, 2026-06-16 22:00Z).
    const now = new Date("2026-06-16T20:00:00Z");
    const { start, end } = localDayBoundsUtc(now, "Europe/Madrid");
    expect(start.toISOString()).toBe("2026-06-15T22:00:00.000Z");
    expect(end.toISOString()).toBe("2026-06-16T22:00:00.000Z");
  });

  it("usa horario de invierno en Europe/Madrid (+01:00)", () => {
    const now = new Date("2026-01-15T12:00:00Z"); // 13:00 Madrid
    const { start, end } = localDayBoundsUtc(now, "Europe/Madrid");
    expect(start.toISOString()).toBe("2026-01-14T23:00:00.000Z");
    expect(end.toISOString()).toBe("2026-01-15T23:00:00.000Z");
  });

  it("trata UTC como día natural UTC", () => {
    const now = new Date("2026-06-16T20:00:00Z");
    const { start, end } = localDayBoundsUtc(now, "UTC");
    expect(start.toISOString()).toBe("2026-06-16T00:00:00.000Z");
    expect(end.toISOString()).toBe("2026-06-17T00:00:00.000Z");
  });

  it("maneja el día de cambio a horario de verano (spring-forward, 23h)", () => {
    // En Madrid el 2026-03-29 los relojes saltan de 02:00 a 03:00 (+01→+02).
    // Día local [2026-03-29 00:00 +01:00, 2026-03-30 00:00 +02:00)
    //         = [2026-03-28 23:00Z, 2026-03-29 22:00Z) → 23 horas.
    const now = new Date("2026-03-29T10:00:00Z");
    const { start, end } = localDayBoundsUtc(now, "Europe/Madrid");
    expect(start.toISOString()).toBe("2026-03-28T23:00:00.000Z");
    expect(end.toISOString()).toBe("2026-03-29T22:00:00.000Z");
    expect(end.getTime() - start.getTime()).toBe(23 * 60 * 60 * 1000);
  });

  it("maneja zonas detrás de UTC (America/New_York)", () => {
    // 2026-06-16 12:00 Nueva York (= 16:00Z, EDT -04:00). Día local
    // [2026-06-16 00:00 -04:00, 2026-06-17 00:00 -04:00)
    //         = [2026-06-16 04:00Z, 2026-06-17 04:00Z).
    const now = new Date("2026-06-16T16:00:00Z");
    const { start, end } = localDayBoundsUtc(now, "America/New_York");
    expect(start.toISOString()).toBe("2026-06-16T04:00:00.000Z");
    expect(end.toISOString()).toBe("2026-06-17T04:00:00.000Z");
  });

  it("cae a Europe/Madrid si la zona es inválida", () => {
    const now = new Date("2026-06-16T20:00:00Z");
    const bad = localDayBoundsUtc(now, "Not/AZone");
    const madrid = localDayBoundsUtc(now, "Europe/Madrid");
    expect(bad.start.toISOString()).toBe(madrid.start.toISOString());
    expect(bad.end.toISOString()).toBe(madrid.end.toISOString());
  });
});

describe("classifyDue (zona del hogar)", () => {
  const now = new Date("2026-06-16T20:00:00Z"); // 22:00 Madrid
  const bounds = localDayBoundsUtc(now, "Europe/Madrid");
  // bounds = [2026-06-15 22:00Z, 2026-06-16 22:00Z)

  it("una tarea a las 23:00 de hoy (Madrid) cuenta como 'today'", () => {
    const due = new Date("2026-06-16T21:00:00Z"); // 23:00 Madrid hoy
    expect(classifyDue(due, bounds)).toBe("today");
  });

  it("una tarea a las 00:30 de mañana (Madrid) NO cuenta como 'today'", () => {
    // 00:30 Madrid del 17 = 22:30Z del 16. En UTC sería 'hoy' (16), pero en
    // Madrid ya es mañana → debe ser 'future'. Esta es la discrepancia del bug.
    const due = new Date("2026-06-16T22:30:00Z");
    expect(classifyDue(due, bounds)).toBe("future");
  });

  it("una tarea de ayer por la noche (Madrid) es 'overdue'", () => {
    const due = new Date("2026-06-15T21:00:00Z"); // 23:00 Madrid del 15
    expect(classifyDue(due, bounds)).toBe("overdue");
  });

  it("el instante exacto del inicio del día cuenta como 'today'", () => {
    expect(classifyDue(bounds.start, bounds)).toBe("today");
  });

  it("el instante exacto del fin del día cuenta como 'future' (mañana)", () => {
    expect(classifyDue(bounds.end, bounds)).toBe("future");
  });
});

describe("summarizeDue (agregador del dashboard, fechas fijas)", () => {
  const now = new Date("2026-06-16T20:00:00Z"); // 22:00 Madrid

  it("cuenta SOLO las de hoy en tasksDueToday (estricto, sin vencidas)", () => {
    const dates = [
      new Date("2026-06-15T21:00:00Z"), // ayer 23:00 Madrid → overdue
      new Date("2026-06-16T07:00:00Z"), // hoy 09:00 Madrid → today
      new Date("2026-06-16T21:00:00Z"), // hoy 23:00 Madrid → today
      new Date("2026-06-16T22:30:00Z"), // mañana 00:30 Madrid → future
      new Date("2026-06-20T10:00:00Z"), // dentro de 4 días → future
    ];
    const s = summarizeDue(dates, now, "Europe/Madrid");
    expect(s.dueTodayCount).toBe(2);
    // pendingToday = vencidas + hoy = 1 + 2 = 3
    expect(s.pendingTodayCount).toBe(3);
  });

  it("reproduce el bug: una única tarea a las 00:30 de mañana NO cuenta como hoy", () => {
    // Antes (ventana UTC) esta tarea (22:30Z del 16) caía en 'hoy' UTC y se
    // contaba; en Madrid ya es mañana → tasksDueToday debe ser 0.
    const s = summarizeDue([new Date("2026-06-16T22:30:00Z")], now, "Europe/Madrid");
    expect(s.dueTodayCount).toBe(0);
    expect(s.pendingTodayCount).toBe(0);
  });

  it("devuelve los límites del día usados para clasificar", () => {
    const s = summarizeDue([], now, "Europe/Madrid");
    expect(s.bounds.start.toISOString()).toBe("2026-06-15T22:00:00.000Z");
    expect(s.bounds.end.toISOString()).toBe("2026-06-16T22:00:00.000Z");
    expect(s.dueTodayCount).toBe(0);
    expect(s.pendingTodayCount).toBe(0);
  });
});

describe("normalizeTimeZone", () => {
  it("conserva una zona IANA válida", () => {
    expect(normalizeTimeZone("Europe/Bucharest")).toBe("Europe/Bucharest");
  });
  it("cae al default si es inválida, vacía o nula", () => {
    expect(normalizeTimeZone("Not/AZone")).toBe(DEFAULT_HOME_TIMEZONE);
    expect(normalizeTimeZone("")).toBe(DEFAULT_HOME_TIMEZONE);
    expect(normalizeTimeZone(undefined)).toBe(DEFAULT_HOME_TIMEZONE);
  });
});

describe("DEFAULT_HOME_TIMEZONE", () => {
  it("es Europe/Madrid", () => {
    expect(DEFAULT_HOME_TIMEZONE).toBe("Europe/Madrid");
  });
});
