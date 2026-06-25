// functions/src/shared/tier_catalog.test.ts
import {
  tierFromProductId,
  maxMembersForTier,
  resolveEntitlement,
  effectiveMaxMembers,
  TIER_MAX_MEMBERS,
  FREE_MAX_MEMBERS,
  BINARY_PREMIUM_MAX_MEMBERS,
  ABSOLUTE_MAX_MEMBERS,
  type HomeTier,
} from "./tier_catalog";

describe("tierFromProductId", () => {
  it("mapea los 6 SKUs de tier a su tier", () => {
    expect(tierFromProductId("toka_pareja_monthly")).toBe("pareja");
    expect(tierFromProductId("toka_pareja_annual")).toBe("pareja");
    expect(tierFromProductId("toka_familia_monthly")).toBe("familia");
    expect(tierFromProductId("toka_familia_annual")).toBe("familia");
    expect(tierFromProductId("toka_grupo_monthly")).toBe("grupo");
    expect(tierFromProductId("toka_grupo_annual")).toBe("grupo");
  });

  it("mapea los SKUs legacy toka_premium_* a Grupo (preserva Premium=10)", () => {
    expect(tierFromProductId("toka_premium_monthly")).toBe("grupo");
    expect(tierFromProductId("toka_premium_annual")).toBe("grupo");
  });

  it("es case-insensitive", () => {
    expect(tierFromProductId("TOKA_FAMILIA_MONTHLY")).toBe("familia");
    expect(tierFromProductId("Toka_Grupo_Annual")).toBe("grupo");
  });

  it("devuelve null para productId desconocido, vacío o null", () => {
    expect(tierFromProductId("toka_otra_cosa")).toBeNull();
    expect(tierFromProductId("")).toBeNull();
    expect(tierFromProductId(null)).toBeNull();
    expect(tierFromProductId(undefined)).toBeNull();
  });
});

describe("maxMembersForTier", () => {
  it("devuelve el tope exacto de cada tier premium", () => {
    expect(maxMembersForTier("pareja")).toBe(2);
    expect(maxMembersForTier("familia")).toBe(5);
    expect(maxMembersForTier("grupo")).toBe(10);
  });

  it("la tabla TIER_MAX_MEMBERS coincide con la spec de producto", () => {
    expect(TIER_MAX_MEMBERS).toEqual({ pareja: 2, familia: 5, grupo: 10 });
    expect(FREE_MAX_MEMBERS).toBe(3);
    expect(BINARY_PREMIUM_MAX_MEMBERS).toBe(10);
  });
});

describe("resolveEntitlement — flag OFF (binario, comportamiento actual)", () => {
  const tiersEnabled = false;

  it("premium → 10 ignorando el tier/producto", () => {
    expect(
      resolveEntitlement({ premiumStatus: "active", tier: "pareja", tiersEnabled }),
    ).toEqual({ tier: null, maxMembers: 10, failSafe: false });
    expect(
      resolveEntitlement({ premiumStatus: "active", productId: "toka_pareja_monthly", tiersEnabled }),
    ).toEqual({ tier: null, maxMembers: 10, failSafe: false });
  });

  it("cada estado premium (active, cancelledPendingEnd, rescue) → 10", () => {
    for (const status of ["active", "cancelledPendingEnd", "cancelled_pending_end", "rescue"]) {
      expect(resolveEntitlement({ premiumStatus: status, tiersEnabled }).maxMembers).toBe(10);
    }
  });

  it("no premium (free, restorable, expiredFree, purged, null) → 3", () => {
    for (const status of ["free", "restorable", "expiredFree", "purged", null, undefined]) {
      expect(resolveEntitlement({ premiumStatus: status, tiersEnabled }).maxMembers).toBe(3);
    }
  });
});

describe("resolveEntitlement — flag ON (modelo de tiers)", () => {
  const tiersEnabled = true;

  it("no premium → Free (3) aunque tenga un premiumTier sticky", () => {
    expect(
      resolveEntitlement({ premiumStatus: "restorable", tier: "grupo", tiersEnabled }),
    ).toEqual({ tier: "free", maxMembers: 3, failSafe: false });
    expect(
      resolveEntitlement({ premiumStatus: "free", tiersEnabled }),
    ).toEqual({ tier: "free", maxMembers: 3, failSafe: false });
  });

  it("premium con tier persistido → tope del tier", () => {
    expect(resolveEntitlement({ premiumStatus: "active", tier: "pareja", tiersEnabled }))
      .toEqual({ tier: "pareja", maxMembers: 2, failSafe: false });
    expect(resolveEntitlement({ premiumStatus: "active", tier: "familia", tiersEnabled }))
      .toEqual({ tier: "familia", maxMembers: 5, failSafe: false });
    expect(resolveEntitlement({ premiumStatus: "rescue", tier: "grupo", tiersEnabled }))
      .toEqual({ tier: "grupo", maxMembers: 10, failSafe: false });
  });

  it("premium derivando el tier desde el productId (cada SKU → su tope)", () => {
    const cases: Array<[string, HomeTier, number]> = [
      ["toka_pareja_monthly", "pareja", 2],
      ["toka_pareja_annual", "pareja", 2],
      ["toka_familia_monthly", "familia", 5],
      ["toka_familia_annual", "familia", 5],
      ["toka_grupo_monthly", "grupo", 10],
      ["toka_grupo_annual", "grupo", 10],
      ["toka_premium_monthly", "grupo", 10],
      ["toka_premium_annual", "grupo", 10],
    ];
    for (const [productId, tier, max] of cases) {
      expect(resolveEntitlement({ premiumStatus: "active", productId, tiersEnabled }))
        .toEqual({ tier, maxMembers: max, failSafe: false });
    }
  });

  it("premium con producto DESCONOCIDO → fail-safe Free (3) marcado", () => {
    expect(
      resolveEntitlement({ premiumStatus: "active", productId: "toka_desconocido", tiersEnabled }),
    ).toEqual({ tier: "free", maxMembers: 3, failSafe: true });
  });

  it("premium SIN tier ni productId → fail-safe Free (3) marcado", () => {
    expect(resolveEntitlement({ premiumStatus: "active", tiersEnabled }))
      .toEqual({ tier: "free", maxMembers: 3, failSafe: true });
  });

  it("el tier persistido tiene prioridad sobre el productId", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        tier: "familia",
        productId: "toka_grupo_monthly",
        tiersEnabled,
      }),
    ).toEqual({ tier: "familia", maxMembers: 5, failSafe: false });
  });
});

describe("effectiveMaxMembers (packs aditivos sobre el tope del tier)", () => {
  it("ABSOLUTE_MAX_MEMBERS es 25 (= 10 + 5 + 10)", () => {
    expect(ABSOLUTE_MAX_MEMBERS).toBe(25);
  });

  describe("solo Grupo admite packs", () => {
    it("Grupo (10): ninguno→10, +5→15, +10→20, ambos→25", () => {
      expect(effectiveMaxMembers("grupo", 10, {}, true)).toBe(10);
      expect(effectiveMaxMembers("grupo", 10, { plus5: true }, true)).toBe(15);
      expect(effectiveMaxMembers("grupo", 10, { plus10: true }, true)).toBe(20);
      expect(
        effectiveMaxMembers("grupo", 10, { plus5: true, plus10: true }, true),
      ).toBe(25);
    });

    it("Grupo con ambos packs queda capado a 25 (nunca lo supera)", () => {
      expect(
        effectiveMaxMembers("grupo", 10, { plus5: true, plus10: true }, true),
      ).toBeLessThanOrEqual(ABSOLUTE_MAX_MEMBERS);
      expect(
        effectiveMaxMembers("grupo", 10, { plus5: true, plus10: true }, true),
      ).toBe(ABSOLUTE_MAX_MEMBERS);
    });

    it("Pareja/Familia/Free ignoran los packs (tope del tier)", () => {
      expect(
        effectiveMaxMembers("pareja", 2, { plus5: true, plus10: true }, true),
      ).toBe(2);
      expect(
        effectiveMaxMembers("familia", 5, { plus5: true, plus10: true }, true),
      ).toBe(5);
      expect(
        effectiveMaxMembers("free", 3, { plus5: true, plus10: true }, true),
      ).toBe(3);
    });

    it("tier null (modo binario) ignora los packs", () => {
      expect(
        effectiveMaxMembers(null, 10, { plus5: true, plus10: true }, true),
      ).toBe(10);
    });
  });

  it("flag de packs OFF → tope del tier aunque haya packs activos", () => {
    expect(
      effectiveMaxMembers("grupo", 10, { plus5: true, plus10: true }, false),
    ).toBe(10);
    expect(effectiveMaxMembers("grupo", 10, { plus5: true }, false)).toBe(10);
  });
});

describe("resolveEntitlement — packs (flag tiers ON)", () => {
  const tiersEnabled = true;

  it("Grupo + packsEnabled: ninguno→10, +5→15, +10→20, ambos→25", () => {
    const base = { premiumStatus: "active", tier: "grupo" as HomeTier, tiersEnabled, packsEnabled: true };
    expect(resolveEntitlement({ ...base, packs: {} }).maxMembers).toBe(10);
    expect(resolveEntitlement({ ...base, packs: { plus5: true } }).maxMembers).toBe(15);
    expect(resolveEntitlement({ ...base, packs: { plus10: true } }).maxMembers).toBe(20);
    expect(
      resolveEntitlement({ ...base, packs: { plus5: true, plus10: true } }).maxMembers,
    ).toBe(25);
  });

  it("el tier sigue siendo 'grupo' con packs (los packs no cambian el tier)", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        tier: "grupo",
        tiersEnabled,
        packsEnabled: true,
        packs: { plus5: true, plus10: true },
      }),
    ).toEqual({ tier: "grupo", maxMembers: 25, failSafe: false });
  });

  it("packsEnabled OFF → tope del tier (Grupo 10) ignorando packs", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        tier: "grupo",
        tiersEnabled,
        packsEnabled: false,
        packs: { plus5: true, plus10: true },
      }).maxMembers,
    ).toBe(10);
  });

  it("packs sobre Familia/Pareja se ignoran (requieren Grupo)", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        tier: "familia",
        tiersEnabled,
        packsEnabled: true,
        packs: { plus5: true, plus10: true },
      }).maxMembers,
    ).toBe(5);
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        tier: "pareja",
        tiersEnabled,
        packsEnabled: true,
        packs: { plus10: true },
      }).maxMembers,
    ).toBe(2);
  });

  it("no premium + packs → Free (3), packs ignorados", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "restorable",
        tier: "grupo",
        tiersEnabled,
        packsEnabled: true,
        packs: { plus5: true, plus10: true },
      }).maxMembers,
    ).toBe(3);
  });

  it("no pasar packs/packsEnabled → comportamiento idéntico al previo (retrocompat)", () => {
    expect(
      resolveEntitlement({ premiumStatus: "active", tier: "grupo", tiersEnabled }),
    ).toEqual({ tier: "grupo", maxMembers: 10, failSafe: false });
  });
});

describe("resolveEntitlement — packs con flag de tiers OFF (binario)", () => {
  it("binario + packs → 10 (no existe el concepto Grupo)", () => {
    expect(
      resolveEntitlement({
        premiumStatus: "active",
        productId: "toka_grupo_monthly",
        tiersEnabled: false,
        packsEnabled: true,
        packs: { plus5: true, plus10: true },
      }).maxMembers,
    ).toBe(10);
  });
});
