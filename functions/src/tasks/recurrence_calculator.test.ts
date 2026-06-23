// functions/src/tasks/recurrence_calculator.test.ts
//
// Paridad con lib/core/utils/recurrence_calculator.dart (cliente) + casos DST
// y todos los modos mensual/anual. La 2ª ocurrencia en adelante debe derivarse
// de la RecurrenceRule en la zona del hogar (tz-aware), manteniendo la hora de
// pared estable a través de los cambios de horario de verano.

import { DateTime } from "luxon";
import {
  parseRecurrenceRule,
  nextDue,
  computeNextDueAt,
} from "./recurrence_calculator";

const TZ = "Europe/Madrid";

/** Date (instante) que representa una hora de pared concreta en Europe/Madrid. */
function madrid(y: number, mo: number, d: number, h = 0, mi = 0): Date {
  return DateTime.fromObject(
    { year: y, month: mo, day: d, hour: h, minute: mi },
    { zone: TZ }
  ).toJSDate();
}

/** Convierte un instante a la hora de pared de Europe/Madrid. */
function toMadrid(date: Date): DateTime {
  return DateTime.fromJSDate(date, { zone: TZ });
}

function rule(map: Record<string, unknown>) {
  return parseRecurrenceRule(map);
}

describe("nextDue — Daily (paridad cliente)", () => {
  const daily = (every: number, time: string) =>
    rule({ type: "daily", every, time, timezone: TZ });

  it("mismo día antes de la hora → hoy a esa hora", () => {
    const r = daily(1, "20:00");
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0)));
    expect(n.day).toBe(7);
    expect(n.hour).toBe(20);
  });

  it("mismo día después de la hora → mañana a esa hora", () => {
    const r = daily(1, "20:00");
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 21, 0)));
    expect(n.day).toBe(8);
    expect(n.hour).toBe(20);
  });

  it("cada 3 días", () => {
    const r = daily(3, "09:00");
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0)));
    expect(n.day).toBe(10);
  });
});

describe("nextDue — Daily a través de DST (hora de pared estable)", () => {
  const r = rule({ type: "daily", every: 1, time: "09:00", timezone: TZ });

  it("spring-forward (31-mar-2024): la diaria 09:00 NO deriva a las 10:00", () => {
    // 30-mar 10:00 (ya pasó 09:00) → 31-mar (día del cambio) 09:00.
    const next1 = nextDue(r, madrid(2024, 3, 30, 10, 0));
    const m1 = toMadrid(next1);
    expect(m1.day).toBe(31);
    expect(m1.hour).toBe(9);
    expect(m1.minute).toBe(0);
    // Instante en CEST (+02:00) = 07:00Z; el bug viejo (suma UTC) daría 10:00 local.
    expect(next1.toISOString()).toBe("2024-03-31T07:00:00.000Z");
    // Siguiente salto tras el cambio: sigue a las 09:00.
    const m2 = toMadrid(nextDue(r, next1));
    expect(m2.day).toBe(1);
    expect(m2.month).toBe(4);
    expect(m2.hour).toBe(9);
  });

  it("fall-back (27-oct-2024): la diaria 09:00 se mantiene a las 09:00", () => {
    const next1 = nextDue(r, madrid(2024, 10, 26, 10, 0));
    const m1 = toMadrid(next1);
    expect(m1.day).toBe(27);
    expect(m1.hour).toBe(9);
    // CET (+01:00) = 08:00Z.
    expect(next1.toISOString()).toBe("2024-10-27T08:00:00.000Z");
    const m2 = toMadrid(nextDue(r, next1));
    expect(m2.day).toBe(28);
    expect(m2.hour).toBe(9);
  });
});

describe("nextDue — Weekly", () => {
  it("próximo lunes desde martes (un solo weekday)", () => {
    const r = rule({ type: "weekly", weekdays: ["MON"], time: "09:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0))); // martes
    expect(n.weekday).toBe(1); // lunes
    expect(n.day).toBe(13);
  });

  it("hoy es día válido pero antes de la hora → hoy", () => {
    const r = rule({ type: "weekly", weekdays: ["MON"], time: "20:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 6, 10, 0))); // lunes 10:00
    expect(n.weekday).toBe(1);
    expect(n.day).toBe(6);
  });

  it("varios weekdays → avanza al SIGUIENTE día de la semana, no +7", () => {
    const r = rule({ type: "weekly", weekdays: ["MON", "WED", "FRI"], time: "09:00", timezone: TZ });
    // lunes 6-abr 10:00 (ya pasó 09:00 del lunes) → miércoles 8-abr, no lunes 13.
    const n = toMadrid(nextDue(r, madrid(2026, 4, 6, 10, 0)));
    expect(n.weekday).toBe(3); // miércoles
    expect(n.day).toBe(8);
  });

  it("último día válido de la semana → salta a la semana siguiente", () => {
    const r = rule({ type: "weekly", weekdays: ["MON", "WED", "FRI"], time: "09:00", timezone: TZ });
    // viernes 10-abr 10:00 → lunes 13-abr.
    const n = toMadrid(nextDue(r, madrid(2026, 4, 10, 10, 0)));
    expect(n.weekday).toBe(1);
    expect(n.day).toBe(13);
  });
});

describe("nextDue — Monthly Fixed", () => {
  const mf = (day: number) => rule({ type: "monthlyFixed", day, time: "09:00", timezone: TZ });

  it("día 15 del mes actual si no ha pasado", () => {
    const n = toMadrid(nextDue(mf(15), madrid(2026, 4, 7, 10, 0)));
    expect(n.month).toBe(4);
    expect(n.day).toBe(15);
  });

  it("ya pasó el 15 → día 15 del mes siguiente", () => {
    const n = toMadrid(nextDue(mf(15), madrid(2026, 4, 16, 10, 0)));
    expect(n.month).toBe(5);
    expect(n.day).toBe(15);
  });

  it("día 31 en mes de 30 días → clamp a 30", () => {
    const n = toMadrid(nextDue(mf(31), madrid(2026, 4, 1, 10, 0)));
    expect(n.month).toBe(4);
    expect(n.day).toBe(30);
  });

  it("día 31 en febrero no bisiesto → clamp a 28", () => {
    const n = toMadrid(nextDue(mf(31), madrid(2026, 2, 1, 10, 0)));
    expect(n.month).toBe(2);
    expect(n.day).toBe(28);
  });

  it("día 31 en febrero bisiesto → clamp a 29", () => {
    const n = toMadrid(nextDue(mf(31), madrid(2028, 2, 1, 10, 0)));
    expect(n.month).toBe(2);
    expect(n.day).toBe(29);
  });
});

describe("nextDue — Monthly Nth (no es +1 mes)", () => {
  const mn = rule({
    type: "monthlyNth",
    weekOfMonth: 2,
    weekday: "TUE",
    time: "09:00",
    timezone: TZ,
  });

  it("2.º martes de abril 2026 = día 14", () => {
    const n = toMadrid(nextDue(mn, madrid(2026, 4, 1, 0, 0)));
    expect(n.weekday).toBe(2);
    expect(n.month).toBe(4);
    expect(n.day).toBe(14);
  });

  it("tras el 2.º martes de abril → 2.º martes de mayo = día 12 (recalculado)", () => {
    const n = toMadrid(nextDue(mn, madrid(2026, 4, 14, 9, 0)));
    expect(n.weekday).toBe(2);
    expect(n.month).toBe(5);
    expect(n.day).toBe(12);
  });
});

describe("nextDue — Yearly Fixed", () => {
  it("15 de marzo del año siguiente si ya pasó", () => {
    const r = rule({ type: "yearlyFixed", month: 3, day: 15, time: "09:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0)));
    expect(n.year).toBe(2027);
    expect(n.month).toBe(3);
    expect(n.day).toBe(15);
  });

  it("29 de febrero → clamp a 28 en año no bisiesto", () => {
    const r = rule({ type: "yearlyFixed", month: 2, day: 29, time: "09:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 6, 1, 10, 0))); // 2027 no bisiesto
    expect(n.year).toBe(2027);
    expect(n.month).toBe(2);
    expect(n.day).toBe(28);
  });
});

describe("nextDue — Yearly Nth", () => {
  it("primer lunes de marzo 2027 = día 1", () => {
    const r = rule({
      type: "yearlyNth",
      month: 3,
      weekOfMonth: 1,
      weekday: "MON",
      time: "09:00",
      timezone: TZ,
    });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0)));
    expect(n.year).toBe(2027);
    expect(n.month).toBe(3);
    expect(n.weekday).toBe(1);
    expect(n.day).toBe(1);
  });
});

describe("nextDue — Hourly", () => {
  it("añade N horas", () => {
    const r = rule({ type: "hourly", every: 4, startTime: "08:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 10, 0)));
    expect(n.hour).toBe(14);
  });

  it("con endTime: supera el límite → día siguiente a startTime", () => {
    const r = rule({ type: "hourly", every: 4, startTime: "08:00", endTime: "20:00", timezone: TZ });
    const n = toMadrid(nextDue(r, madrid(2026, 4, 7, 18, 0))); // 18+4=22 > 20
    expect(n.day).toBe(8);
    expect(n.hour).toBe(8);
  });
});

describe("parseRecurrenceRule", () => {
  it("acepta el discriminante en 'kind' además de 'type'", () => {
    const r = parseRecurrenceRule({ kind: "daily", every: 2, time: "07:30", timezone: TZ });
    expect(r.kind).toBe("daily");
    if (r.kind === "daily") {
      expect(r.every).toBe(2);
      expect(r.time).toBe("07:30");
    }
  });

  it("aplica defaults cuando faltan campos", () => {
    const r = parseRecurrenceRule({ type: "weekly" });
    expect(r.kind).toBe("weekly");
    if (r.kind === "weekly") {
      expect(r.weekdays).toEqual(["MON"]);
      expect(r.time).toBe("09:00");
      expect(r.timezone).toBe("UTC");
    }
  });

  it("tipo desconocido → daily por defecto", () => {
    const r = parseRecurrenceRule({ type: "garbage" });
    expect(r.kind).toBe("daily");
  });
});

describe("computeNextDueAt", () => {
  it("usa recurrenceRule del task (tz-aware) ignorando el recurrenceType grueso", () => {
    const task = {
      recurrenceType: "daily",
      recurrenceRule: { type: "daily", every: 1, time: "09:00", timezone: TZ },
    };
    const next = computeNextDueAt(task, madrid(2024, 3, 30, 9, 0));
    expect(toMadrid(next).day).toBe(31);
    expect(toMadrid(next).hour).toBe(9); // estable en DST
  });

  it("oneTime → devuelve currentDue sin modificar (terminal)", () => {
    const due = madrid(2026, 4, 7, 9, 0);
    const task = {
      recurrenceType: "oneTime",
      recurrenceRule: { type: "oneTime", date: "2026-04-07", time: "09:00", timezone: TZ },
    };
    expect(computeNextDueAt(task, due).getTime()).toBe(due.getTime());
  });

  it("fallback sin recurrenceRule: usa recurrenceType en UTC (compat legacy)", () => {
    const due = new Date("2026-04-08T10:00:00Z");
    const next = computeNextDueAt({ recurrenceType: "daily" }, due);
    // +1 día UTC manteniendo la hora UTC (comportamiento anterior, sin DST).
    expect(next.toISOString()).toBe("2026-04-09T10:00:00.000Z");
  });

  it("fallback monthly sin recurrenceRule respeta el día del currentDue en UTC", () => {
    const due = new Date("2026-01-15T08:00:00Z");
    const next = computeNextDueAt({ recurrenceType: "monthly" }, due);
    expect(next.toISOString()).toBe("2026-02-15T08:00:00.000Z");
  });
});
