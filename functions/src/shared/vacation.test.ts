import * as admin from "firebase-admin";
import { isMemberCurrentlyAbsent } from "./vacation";

// Mock mínimo de Timestamp (solo necesitamos toMillis).
const ts = (ms: number) => ({ toMillis: () => ms } as admin.firestore.Timestamp);
const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_700_000 * DAY; // instante fijo arbitrario

describe("isMemberCurrentlyAbsent", () => {
  it("false sin vacación ni status absent", () => {
    expect(isMemberCurrentlyAbsent({ status: "active" }, NOW)).toBe(false);
  });

  it("false si mData es undefined", () => {
    expect(isMemberCurrentlyAbsent(undefined, NOW)).toBe(false);
  });

  it("false aunque status sea 'absent' (legacy) si no hay vacación activa", () => {
    // La ausencia se basa SOLO en `vacation`, no en un status stale.
    expect(isMemberCurrentlyAbsent({ status: "absent" }, NOW)).toBe(false);
  });

  it("false si vacation.isActive es false", () => {
    expect(isMemberCurrentlyAbsent({ vacation: { isActive: false } }, NOW)).toBe(false);
  });

  it("true si vacación activa SIN fechas (indefinida)", () => {
    expect(isMemberCurrentlyAbsent({ vacation: { isActive: true } }, NOW)).toBe(true);
  });

  it("false si hoy es ANTES de startDate", () => {
    expect(
      isMemberCurrentlyAbsent({ vacation: { isActive: true, startDate: ts(NOW + DAY) } }, NOW)
    ).toBe(false);
  });

  it("true si hoy >= startDate", () => {
    expect(
      isMemberCurrentlyAbsent({ vacation: { isActive: true, startDate: ts(NOW - DAY) } }, NOW)
    ).toBe(true);
  });

  it("true el propio día de endDate (inclusivo, +24h)", () => {
    // endDate ~5h antes de ahora (mismo día) → sigue ausente.
    expect(
      isMemberCurrentlyAbsent({ vacation: { isActive: true, endDate: ts(NOW - 5 * 60 * 60 * 1000) } }, NOW)
    ).toBe(true);
  });

  it("false pasado el día de endDate", () => {
    expect(
      isMemberCurrentlyAbsent({ vacation: { isActive: true, endDate: ts(NOW - 2 * DAY) } }, NOW)
    ).toBe(false);
  });

  it("true dentro del rango [start, end]", () => {
    expect(
      isMemberCurrentlyAbsent(
        { vacation: { isActive: true, startDate: ts(NOW - DAY), endDate: ts(NOW + DAY) } },
        NOW
      )
    ).toBe(true);
  });
});
