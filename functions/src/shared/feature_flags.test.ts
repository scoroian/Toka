// functions/src/shared/feature_flags.test.ts
import {
  isHomeTiersEnabled,
  __setHomeTiersEnabledForTesting,
  __setTiersFetcherForTesting,
  isTokaPlusEnabled,
  __setTokaPlusEnabledForTesting,
  __setPlusFetcherForTesting,
  isMemberPacksEnabled,
  __setMemberPacksEnabledForTesting,
  __setPacksFetcherForTesting,
} from "./feature_flags";

afterEach(() => {
  // Restaurar estado global del módulo entre tests.
  __setHomeTiersEnabledForTesting(undefined);
  __setTiersFetcherForTesting(undefined);
  __setTokaPlusEnabledForTesting(undefined);
  __setPlusFetcherForTesting(undefined);
  __setMemberPacksEnabledForTesting(undefined);
  __setPacksFetcherForTesting(undefined);
});

describe("isHomeTiersEnabled — override de tests", () => {
  it("devuelve el valor inyectado (true)", async () => {
    __setHomeTiersEnabledForTesting(true);
    expect(await isHomeTiersEnabled()).toBe(true);
  });

  it("devuelve el valor inyectado (false)", async () => {
    __setHomeTiersEnabledForTesting(false);
    expect(await isHomeTiersEnabled()).toBe(false);
  });

  it("el override tiene prioridad sobre el fetcher", async () => {
    __setTiersFetcherForTesting(async () => true);
    __setHomeTiersEnabledForTesting(false);
    expect(await isHomeTiersEnabled()).toBe(false);
  });
});

describe("isHomeTiersEnabled — lectura del flag", () => {
  it("devuelve el valor que da el fetcher (Remote Config)", async () => {
    __setTiersFetcherForTesting(async () => true);
    expect(await isHomeTiersEnabled()).toBe(true);
  });

  it("default OFF si el fetcher lanza (RC no disponible)", async () => {
    __setTiersFetcherForTesting(async () => {
      throw new Error("remote config unavailable");
    });
    expect(await isHomeTiersEnabled()).toBe(false);
  });
});

describe("isHomeTiersEnabled — caché con TTL", () => {
  it("cachea el resultado dentro de la ventana TTL (no re-fetch)", async () => {
    let calls = 0;
    __setTiersFetcherForTesting(async () => {
      calls++;
      return true;
    });
    const t0 = 1_000_000;
    expect(await isHomeTiersEnabled(t0)).toBe(true);
    expect(await isHomeTiersEnabled(t0 + 60_000)).toBe(true); // 1 min después
    expect(calls).toBe(1);
  });

  it("re-fetch cuando expira el TTL (>5 min)", async () => {
    let calls = 0;
    __setTiersFetcherForTesting(async () => {
      calls++;
      return true;
    });
    const t0 = 1_000_000;
    expect(await isHomeTiersEnabled(t0)).toBe(true);
    expect(await isHomeTiersEnabled(t0 + 6 * 60_000)).toBe(true); // 6 min después
    expect(calls).toBe(2);
  });
});

describe("isTokaPlusEnabled — flag de Remote Config del eje Plus", () => {
  it("devuelve el valor inyectado por override (true/false)", async () => {
    __setTokaPlusEnabledForTesting(true);
    expect(await isTokaPlusEnabled()).toBe(true);
    __setTokaPlusEnabledForTesting(false);
    expect(await isTokaPlusEnabled()).toBe(false);
  });

  it("el override tiene prioridad sobre el fetcher", async () => {
    __setPlusFetcherForTesting(async () => true);
    __setTokaPlusEnabledForTesting(false);
    expect(await isTokaPlusEnabled()).toBe(false);
  });

  it("devuelve el valor del fetcher (Remote Config)", async () => {
    __setPlusFetcherForTesting(async () => true);
    expect(await isTokaPlusEnabled()).toBe(true);
  });

  it("default OFF si el fetcher lanza (RC no disponible)", async () => {
    __setPlusFetcherForTesting(async () => {
      throw new Error("remote config unavailable");
    });
    expect(await isTokaPlusEnabled()).toBe(false);
  });

  it("cachea dentro del TTL y re-fetch al expirar (independiente de tiers)", async () => {
    let calls = 0;
    __setPlusFetcherForTesting(async () => {
      calls++;
      return true;
    });
    const t0 = 2_000_000;
    expect(await isTokaPlusEnabled(t0)).toBe(true);
    expect(await isTokaPlusEnabled(t0 + 60_000)).toBe(true); // cacheado
    expect(calls).toBe(1);
    expect(await isTokaPlusEnabled(t0 + 6 * 60_000)).toBe(true); // TTL expirado
    expect(calls).toBe(2);
  });

  it("la caché de Plus es independiente de la de tiers", async () => {
    __setTiersFetcherForTesting(async () => false);
    __setPlusFetcherForTesting(async () => true);
    expect(await isHomeTiersEnabled()).toBe(false);
    expect(await isTokaPlusEnabled()).toBe(true);
  });
});

describe("isMemberPacksEnabled — flag de Remote Config de los packs de miembro", () => {
  it("devuelve el valor inyectado por override (true/false)", async () => {
    __setMemberPacksEnabledForTesting(true);
    expect(await isMemberPacksEnabled()).toBe(true);
    __setMemberPacksEnabledForTesting(false);
    expect(await isMemberPacksEnabled()).toBe(false);
  });

  it("el override tiene prioridad sobre el fetcher", async () => {
    __setPacksFetcherForTesting(async () => true);
    __setMemberPacksEnabledForTesting(false);
    expect(await isMemberPacksEnabled()).toBe(false);
  });

  it("devuelve el valor del fetcher (Remote Config)", async () => {
    __setPacksFetcherForTesting(async () => true);
    expect(await isMemberPacksEnabled()).toBe(true);
  });

  it("default OFF si el fetcher lanza (RC no disponible)", async () => {
    __setPacksFetcherForTesting(async () => {
      throw new Error("remote config unavailable");
    });
    expect(await isMemberPacksEnabled()).toBe(false);
  });

  it("cachea dentro del TTL y re-fetch al expirar", async () => {
    let calls = 0;
    __setPacksFetcherForTesting(async () => {
      calls++;
      return true;
    });
    const t0 = 3_000_000;
    expect(await isMemberPacksEnabled(t0)).toBe(true);
    expect(await isMemberPacksEnabled(t0 + 60_000)).toBe(true); // cacheado
    expect(calls).toBe(1);
    expect(await isMemberPacksEnabled(t0 + 6 * 60_000)).toBe(true); // TTL expirado
    expect(calls).toBe(2);
  });

  it("la caché de packs es independiente de tiers y Plus", async () => {
    __setTiersFetcherForTesting(async () => false);
    __setPlusFetcherForTesting(async () => false);
    __setPacksFetcherForTesting(async () => true);
    expect(await isHomeTiersEnabled()).toBe(false);
    expect(await isTokaPlusEnabled()).toBe(false);
    expect(await isMemberPacksEnabled()).toBe(true);
  });
});
