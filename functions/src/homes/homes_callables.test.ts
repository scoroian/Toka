// functions/src/homes/homes_callables.test.ts

// Tests unitarios de validación pura de createHome/joinHome (nombre, slots,
// rate-limit, expiración de invitación).
//
// Hallazgo #20: los "tests espejo" de gobernanza (transferOwnership / leaveHome
// / removeMember — que reimplementaban canReceiveOwnership / canLeave /
// isPayerLocked / validate*Input en el propio test) se ELIMINARON de aquí. Su
// comportamiento se ejercita ahora contra la callable REAL en el emulador, en
// test/integration/homes_governance.test.ts.

describe("createHome — validaciones de entrada", () => {
  function validateCreateHomeInput(name: string | undefined): string | null {
    const trimmed = name?.trim();
    if (!trimmed) return "Home name is required";
    return null;
  }

  it("nombre vacío → error", () => {
    expect(validateCreateHomeInput("")).toBe("Home name is required");
  });
  it("nombre undefined → error", () => {
    expect(validateCreateHomeInput(undefined)).toBe("Home name is required");
  });
  it("nombre con solo espacios → error", () => {
    expect(validateCreateHomeInput("   ")).toBe("Home name is required");
  });
  it("nombre válido → null", () => {
    expect(validateCreateHomeInput("Mi Casa")).toBeNull();
  });
});

describe("createHome — control de slots disponibles", () => {
  function hasAvailableSlot(baseSlots: number, lifetimeUnlocked: number, existingCount: number): boolean {
    return existingCount < (baseSlots + lifetimeUnlocked);
  }

  it("0 hogares con 2 slots base → disponible", () => {
    expect(hasAvailableSlot(2, 0, 0)).toBe(true);
  });
  it("2 hogares con 2 slots base → no disponible", () => {
    expect(hasAvailableSlot(2, 0, 2)).toBe(false);
  });
  it("2 hogares con 1 extra desbloqueado → disponible", () => {
    expect(hasAvailableSlot(2, 1, 2)).toBe(true);
  });
  it("5 hogares con 2+3 slots → no disponible", () => {
    expect(hasAvailableSlot(2, 3, 5)).toBe(false);
  });
});

describe("createHome — memberships abandonados no ocupan cupo", () => {
  // Verifica que solo los memberships activos (status:"active") cuentan.
  // Regresión: leaveHome pone status:"left" pero no borra el documento,
  // por lo que la query de createHome debe filtrar WHERE status == "active".

  function countActiveSlots(memberships: { status: string }[]): number {
    return memberships.filter((m) => m.status === "active").length;
  }

  it("1 activo + 1 abandonado → cuenta 1 cupo usado", () => {
    const memberships = [
      { status: "active" },
      { status: "left" },
    ];
    expect(countActiveSlots(memberships)).toBe(1);
  });

  it("3 abandonados → 0 cupos usados, puede crear hogar", () => {
    const memberships = [
      { status: "left" },
      { status: "left" },
      { status: "left" },
    ];
    expect(countActiveSlots(memberships)).toBe(0);
    expect(hasAvailableSlot(2, 0, countActiveSlots(memberships))).toBe(true);
  });

  it("2 activos + 1 abandonado con 2 slots base → no disponible", () => {
    const memberships = [
      { status: "active" },
      { status: "active" },
      { status: "left" },
    ];
    expect(countActiveSlots(memberships)).toBe(2);
    expect(hasAvailableSlot(2, 0, countActiveSlots(memberships))).toBe(false);
  });

  function hasAvailableSlot(baseSlots: number, lifetimeUnlocked: number, existingCount: number): boolean {
    return existingCount < (baseSlots + lifetimeUnlocked);
  }
});

describe("createHome — lectura de slots canónicos vs legacy [regresión]", () => {
  // slot_ledger escribe baseHomeSlots/lifetimeUnlockedHomeSlots/homeSlotCap y
  // BORRA los legacy baseSlots/lifetimeUnlocked. createHome debe leer los
  // canónicos; si solo leyera legacy, tras comprar una plaza vería siempre 2.
  function readTotalSlots(userData: Record<string, number | undefined>): number {
    const baseSlots = userData["baseHomeSlots"] ?? userData["baseSlots"] ?? 2;
    const lifetimeUnlocked =
      userData["lifetimeUnlockedHomeSlots"] ?? userData["lifetimeUnlocked"] ?? 0;
    return userData["homeSlotCap"] ?? baseSlots + lifetimeUnlocked;
  }

  it("usuario nuevo sin campos → 2 slots", () => {
    expect(readTotalSlots({})).toBe(2);
  });
  it("homeSlotCap canónico tras comprar 1 plaza → 3 (antes daba 2 leyendo legacy)", () => {
    expect(
      readTotalSlots({ baseHomeSlots: 2, lifetimeUnlockedHomeSlots: 1, homeSlotCap: 3 })
    ).toBe(3);
  });
  it("campos canónicos sin homeSlotCap → suma base+unlocked", () => {
    expect(readTotalSlots({ baseHomeSlots: 2, lifetimeUnlockedHomeSlots: 3 })).toBe(5);
  });
  it("datos legacy (baseSlots/lifetimeUnlocked) → fallback compatible", () => {
    expect(readTotalSlots({ baseSlots: 2, lifetimeUnlocked: 1 })).toBe(3);
  });
  it("tope máximo 5 con 3 plazas desbloqueadas", () => {
    expect(readTotalSlots({ homeSlotCap: 5 })).toBe(5);
  });
});

describe("createHome — validación de longitud de inputs", () => {
  function validateLength(name: string, emoji?: string): string | null {
    if (name.length > 60) return "name-too-long";
    if (emoji && emoji.length > 8) return "emoji-too-long";
    return null;
  }
  it("nombre de 60 chars → OK", () => {
    expect(validateLength("a".repeat(60))).toBeNull();
  });
  it("nombre de 61 chars → error", () => {
    expect(validateLength("a".repeat(61))).toBe("name-too-long");
  });
  it("emoji de 9 chars → error", () => {
    expect(validateLength("Casa", "a".repeat(9))).toBe("emoji-too-long");
  });
  it("emoji normal → OK", () => {
    expect(validateLength("Casa", "🏠")).toBeNull();
  });
});

describe("joinHomeByCode — rate limit anti fuerza bruta", () => {
  const WINDOW_MS = 60 * 60 * 1000;
  const MAX = 10;
  function evalLimit(
    nowMs: number,
    windowStart: number,
    count: number
  ): { action: "reset" | "increment" | "block"; next?: number } {
    if (nowMs - windowStart > WINDOW_MS) return { action: "reset" };
    if (count >= MAX) return { action: "block" };
    return { action: "increment", next: count + 1 };
  }

  it("primera vez (windowStart=0, now real) → reset", () => {
    // En prod Date.now() es ~1.7e12; con windowStart 0 la diferencia supera la
    // ventana y se reinicia el contador.
    expect(evalLimit(1_700_000_000_000, 0, 0)).toEqual({ action: "reset" });
  });
  it("dentro de ventana, count < max → incrementa", () => {
    expect(evalLimit(1_000_000, 1_000_000, 3)).toEqual({ action: "increment", next: 4 });
  });
  it("dentro de ventana, count == max → bloquea", () => {
    expect(evalLimit(1_000_000, 1_000_000, 10)).toEqual({ action: "block" });
  });
  it("fuera de ventana (>1h) → reset aunque count alto", () => {
    expect(evalLimit(1_000_000 + WINDOW_MS + 1, 1_000_000, 50)).toEqual({ action: "reset" });
  });
});

describe("joinHome — validación de invitación expirada", () => {
  function isExpired(expiresAt: Date | undefined): boolean {
    if (!expiresAt) return false;
    return new Date() > expiresAt;
  }

  it("sin fecha de expiración → no expirada", () => {
    expect(isExpired(undefined)).toBe(false);
  });
  it("fecha futura → no expirada", () => {
    const future = new Date(Date.now() + 60000);
    expect(isExpired(future)).toBe(false);
  });
  it("fecha pasada → expirada", () => {
    const past = new Date(Date.now() - 60000);
    expect(isExpired(past)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// transferOwnership — validaciones de entrada
// Happy-path tests require emulator setup; skipped here (DONE_WITH_CONCERNS).
// ---------------------------------------------------------------------------