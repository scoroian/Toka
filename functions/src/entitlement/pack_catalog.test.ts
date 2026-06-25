// functions/src/entitlement/pack_catalog.test.ts
import {
  packFromProductId,
  isPackProductId,
  packCycleFromProductId,
  isPackActive,
  isPackEntryActive,
  activePacksFromHome,
  PACK_SEATS,
  PRODUCT_PACK_CATALOG,
  type PackKind,
} from "./pack_catalog";

const ts = (ms: number) => ({ toMillis: () => ms });

describe("packFromProductId", () => {
  it("mapea los 4 SKUs de pack a su kind", () => {
    expect(packFromProductId("toka_pack5_monthly")).toBe("plus5");
    expect(packFromProductId("toka_pack5_annual")).toBe("plus5");
    expect(packFromProductId("toka_pack10_monthly")).toBe("plus10");
    expect(packFromProductId("toka_pack10_annual")).toBe("plus10");
  });

  it("es case-insensitive", () => {
    expect(packFromProductId("TOKA_PACK5_MONTHLY")).toBe("plus5");
    expect(packFromProductId("Toka_Pack10_Annual")).toBe("plus10");
  });

  it("devuelve null para productId desconocido, vacío o null", () => {
    expect(packFromProductId("toka_otra_cosa")).toBeNull();
    expect(packFromProductId("")).toBeNull();
    expect(packFromProductId(null)).toBeNull();
    expect(packFromProductId(undefined)).toBeNull();
  });

  it("NO mapea SKUs de otros ejes (Plus / tiers / legacy premium)", () => {
    for (const other of [
      "toka_plus_monthly",
      "toka_plus_annual",
      "toka_grupo_monthly",
      "toka_familia_annual",
      "toka_pareja_monthly",
      "toka_premium_monthly",
    ]) {
      expect(packFromProductId(other)).toBeNull();
    }
  });
});

describe("isPackProductId", () => {
  it("true solo para los productIds de pack", () => {
    expect(isPackProductId("toka_pack5_monthly")).toBe(true);
    expect(isPackProductId("toka_pack10_annual")).toBe(true);
    expect(isPackProductId("TOKA_PACK5_ANNUAL")).toBe(true);
  });

  it("false para Plus, tiers, legacy y desconocidos (sin colisión de prefijo)", () => {
    for (const other of [
      "toka_plus_monthly", // 'toka_plus' NO empieza por 'toka_pack'
      "toka_grupo_monthly",
      "toka_familia_monthly",
      "toka_pareja_annual",
      "toka_premium_annual",
      "toka_packaging_weird", // prefijo parecido pero no catalogado
      "",
      null,
      undefined,
    ]) {
      expect(isPackProductId(other)).toBe(false);
    }
  });
});

describe("packCycleFromProductId", () => {
  it("deriva el ciclo (annual si contiene 'annual', si no monthly)", () => {
    expect(packCycleFromProductId("toka_pack5_monthly")).toBe("monthly");
    expect(packCycleFromProductId("toka_pack5_annual")).toBe("annual");
    expect(packCycleFromProductId("toka_pack10_annual")).toBe("annual");
    expect(packCycleFromProductId("TOKA_PACK10_MONTHLY")).toBe("monthly");
  });
});

describe("PACK_SEATS / PRODUCT_PACK_CATALOG", () => {
  it("las plazas de cada pack coinciden con la spec de producto", () => {
    expect(PACK_SEATS).toEqual({ plus5: 5, plus10: 10 });
  });

  it("el catálogo cubre exactamente los 4 SKUs", () => {
    expect(Object.keys(PRODUCT_PACK_CATALOG).sort()).toEqual(
      [
        "toka_pack10_annual",
        "toka_pack10_monthly",
        "toka_pack5_annual",
        "toka_pack5_monthly",
      ].sort(),
    );
    const kinds: PackKind[] = Object.values(PRODUCT_PACK_CATALOG);
    expect(new Set(kinds)).toEqual(new Set(["plus5", "plus10"]));
  });
});

describe("isPackActive", () => {
  it("active y cancelledPendingEnd (incl. snake_case legacy) cuentan como vigente", () => {
    expect(isPackActive("active")).toBe(true);
    expect(isPackActive("cancelledPendingEnd")).toBe(true);
    expect(isPackActive("cancelled_pending_end")).toBe(true);
  });

  it("estados sin acceso vigente → false (incluido 'rescue', que no aplica a packs)", () => {
    for (const status of [
      "rescue",
      "expired",
      "expiredFree",
      "refunded",
      "restorable",
      "purged",
      "free",
      null,
      undefined,
    ]) {
      expect(isPackActive(status)).toBe(false);
    }
  });
});

describe("isPackEntryActive (status + guard de endsAt como defensa en profundidad)", () => {
  const now = 1_000_000;

  it("entrada activa con endsAt futuro → true", () => {
    expect(isPackEntryActive({ status: "active", endsAt: ts(now + 1000) }, now)).toBe(true);
  });

  it("entrada activa sin endsAt → true", () => {
    expect(isPackEntryActive({ status: "active", endsAt: null }, now)).toBe(true);
    expect(isPackEntryActive({ status: "cancelledPendingEnd" }, now)).toBe(true);
  });

  it("entrada con endsAt ya pasado → false (notificación de expiración perdida)", () => {
    expect(isPackEntryActive({ status: "active", endsAt: ts(now - 1) }, now)).toBe(false);
    expect(isPackEntryActive({ status: "active", endsAt: ts(now) }, now)).toBe(false);
  });

  it("entrada con status no vigente → false", () => {
    expect(isPackEntryActive({ status: "refunded", endsAt: ts(now + 1000) }, now)).toBe(false);
    expect(isPackEntryActive({ status: "expired" }, now)).toBe(false);
  });

  it("entrada ausente/null → false", () => {
    expect(isPackEntryActive(undefined, now)).toBe(false);
    expect(isPackEntryActive(null, now)).toBe(false);
  });
});

describe("activePacksFromHome (verdad de la store, SIN gatear por flag)", () => {
  const now = 1_000_000;

  it("sin memberPacks → ningún pack activo", () => {
    expect(activePacksFromHome({}, now)).toEqual({ plus5: false, plus10: false });
    expect(activePacksFromHome(undefined, now)).toEqual({ plus5: false, plus10: false });
  });

  it("lee cada pack independientemente", () => {
    const home = {
      memberPacks: {
        plus5: { status: "active", endsAt: ts(now + 1000) },
        plus10: { status: "expired", endsAt: ts(now - 1000) },
      },
    };
    expect(activePacksFromHome(home, now)).toEqual({ plus5: true, plus10: false });
  });

  it("ambos activos → ambos true", () => {
    const home = {
      memberPacks: {
        plus5: { status: "active", endsAt: null },
        plus10: { status: "cancelledPendingEnd", endsAt: ts(now + 5000) },
      },
    };
    expect(activePacksFromHome(home, now)).toEqual({ plus5: true, plus10: true });
  });
});
