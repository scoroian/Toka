// functions/src/entitlement/plus_catalog.test.ts
import {
  isPlusProductId,
  plusCycleFromProductId,
  isPlusActive,
  isPlusEffectivelyActive,
} from "./plus_catalog";

describe("isPlusProductId — mapa productId → efecto (eje Plus)", () => {
  it("reconoce los SKUs de Plus (mensual/anual y pelado)", () => {
    expect(isPlusProductId("toka_plus_monthly")).toBe(true);
    expect(isPlusProductId("toka_plus_annual")).toBe(true);
    expect(isPlusProductId("toka_plus")).toBe(true);
  });

  it("es case-insensitive", () => {
    expect(isPlusProductId("TOKA_PLUS_MONTHLY")).toBe(true);
    expect(isPlusProductId("Toka_Plus_Annual")).toBe(true);
  });

  it("NO confunde productos de hogar (tiers/legacy premium) con Plus", () => {
    expect(isPlusProductId("toka_premium_monthly")).toBe(false);
    expect(isPlusProductId("toka_premium_annual")).toBe(false);
    expect(isPlusProductId("toka_pareja_monthly")).toBe(false);
    expect(isPlusProductId("toka_familia_annual")).toBe(false);
    expect(isPlusProductId("toka_grupo_monthly")).toBe(false);
  });

  it("rechaza vacío / null / undefined / no-toka", () => {
    expect(isPlusProductId("")).toBe(false);
    expect(isPlusProductId(null)).toBe(false);
    expect(isPlusProductId(undefined)).toBe(false);
    expect(isPlusProductId("plus")).toBe(false);
    expect(isPlusProductId("some_other_sku")).toBe(false);
  });
});

describe("plusCycleFromProductId — ciclo derivado del productId", () => {
  it("anual cuando el id contiene 'annual'", () => {
    expect(plusCycleFromProductId("toka_plus_annual")).toBe("annual");
    expect(plusCycleFromProductId("TOKA_PLUS_ANNUAL")).toBe("annual");
  });

  it("mensual en cualquier otro caso (incl. pelado)", () => {
    expect(plusCycleFromProductId("toka_plus_monthly")).toBe("monthly");
    expect(plusCycleFromProductId("toka_plus")).toBe("monthly");
  });
});

describe("isPlusActive — estados de Plus con acceso vigente", () => {
  it("activo: active y cancelledPendingEnd (acceso hasta fin)", () => {
    expect(isPlusActive("active")).toBe(true);
    expect(isPlusActive("cancelledPendingEnd")).toBe(true);
    // variante legacy snake_case aceptada durante migración
    expect(isPlusActive("cancelled_pending_end")).toBe(true);
  });

  it("inactivo: expired, refunded, free, none, rescue (no aplica a Plus)", () => {
    expect(isPlusActive("expired")).toBe(false);
    expect(isPlusActive("refunded")).toBe(false);
    expect(isPlusActive("free")).toBe(false);
    expect(isPlusActive("none")).toBe(false);
    // 'rescue' es un concepto de hogar; en Plus no cuenta como activo
    expect(isPlusActive("rescue")).toBe(false);
  });

  it("rechaza vacío / null / undefined", () => {
    expect(isPlusActive("")).toBe(false);
    expect(isPlusActive(null)).toBe(false);
    expect(isPlusActive(undefined)).toBe(false);
  });
});

describe("isPlusEffectivelyActive — gating del flag al consumir (read-time)", () => {
  const future = { toMillis: () => Date.now() + 10 * 24 * 3600 * 1000 };
  const past = { toMillis: () => Date.now() - 1000 };

  it("activo cuando doc.active=true, flag ON y endsAt futuro", () => {
    expect(isPlusEffectivelyActive({ active: true, endsAt: future }, true)).toBe(true);
  });

  it("FLAG OFF ⇒ inactivo aunque el doc exista y esté activo", () => {
    expect(isPlusEffectivelyActive({ active: true, endsAt: future }, false)).toBe(false);
  });

  it("doc.active=false ⇒ inactivo aunque el flag esté ON", () => {
    expect(isPlusEffectivelyActive({ active: false, endsAt: future }, true)).toBe(false);
  });

  it("endsAt en el pasado ⇒ inactivo (defensa ante notificación perdida)", () => {
    expect(isPlusEffectivelyActive({ active: true, endsAt: past }, true)).toBe(false);
  });

  it("doc null/undefined ⇒ inactivo", () => {
    expect(isPlusEffectivelyActive(null, true)).toBe(false);
    expect(isPlusEffectivelyActive(undefined, true)).toBe(false);
  });

  it("endsAt null + active + flag ON ⇒ activo (sin fecha que invalide)", () => {
    expect(isPlusEffectivelyActive({ active: true, endsAt: null }, true)).toBe(true);
  });

  it("usa el reloj inyectado (nowMs) para evaluar la expiración", () => {
    const t = 1_000_000_000;
    const endsAt = { toMillis: () => t + 5000 };
    expect(isPlusEffectivelyActive({ active: true, endsAt }, true, t)).toBe(true);
    expect(isPlusEffectivelyActive({ active: true, endsAt }, true, t + 6000)).toBe(false);
  });
});
