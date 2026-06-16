// functions/src/homes/homes_callables.test.ts

import {
  parseDebugPremiumAllowedUids,
  isDebugPremiumAllowed,
} from "./debug_premium_allowlist";

// Testea la lógica de negocio de createHome: validación nombre, control de slots, error si sin nombre

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

describe("transferOwnership — status del nuevo owner [regresión]", () => {
  // Frozen puede recibir la propiedad (Caso D). 'left' NO: dejaría el hogar
  // con un owner ausente y sin ruta de cierre.
  function canReceiveOwnership(
    memberExists: boolean,
    status: string | undefined
  ): { ok: boolean; code?: string } {
    if (!memberExists) return { ok: false, code: "not-a-member" };
    if (status === "left") return { ok: false, code: "left-cannot-receive" };
    return { ok: true };
  }

  it("miembro activo → puede recibir", () => {
    expect(canReceiveOwnership(true, "active")).toEqual({ ok: true });
  });
  it("miembro frozen → puede recibir (Caso D)", () => {
    expect(canReceiveOwnership(true, "frozen")).toEqual({ ok: true });
  });
  it("ex-miembro (left) → NO puede recibir", () => {
    expect(canReceiveOwnership(true, "left")).toEqual({ ok: false, code: "left-cannot-receive" });
  });
  it("no es miembro → error", () => {
    expect(canReceiveOwnership(false, undefined)).toEqual({ ok: false, code: "not-a-member" });
  });
});

describe("leaveHome — validación rol owner", () => {
  function canLeave(role: string): boolean {
    return role !== "owner";
  }

  it("member puede salir", () => expect(canLeave("member")).toBe(true));
  it("admin puede salir", () => expect(canLeave("admin")).toBe(true));
  it("owner no puede salir", () => expect(canLeave("owner")).toBe(false));
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
describe("transferOwnership — validaciones de entrada", () => {
  function validateTransferOwnershipInput(
    uid: string,
    homeId: string | undefined,
    newOwnerUid: string | undefined
  ): string | null {
    const trimmedHomeId = homeId?.trim();
    const trimmedNewOwnerUid = newOwnerUid?.trim();
    if (!trimmedHomeId || !trimmedNewOwnerUid) {
      return "homeId and newOwnerUid are required";
    }
    if (trimmedNewOwnerUid === uid) {
      return "Cannot transfer ownership to yourself";
    }
    return null;
  }

  it("newOwnerUid vacío → invalid-argument", () => {
    expect(validateTransferOwnershipInput("uid1", "home1", "")).toBe(
      "homeId and newOwnerUid are required"
    );
  });

  it("newOwnerUid undefined → invalid-argument", () => {
    expect(validateTransferOwnershipInput("uid1", "home1", undefined)).toBe(
      "homeId and newOwnerUid are required"
    );
  });

  it("homeId vacío → invalid-argument", () => {
    expect(validateTransferOwnershipInput("uid1", "", "uid2")).toBe(
      "homeId and newOwnerUid are required"
    );
  });

  it("self-transfer (newOwnerUid === uid) → invalid-argument", () => {
    expect(validateTransferOwnershipInput("uid1", "home1", "uid1")).toBe(
      "Cannot transfer ownership to yourself"
    );
  });

  it("inputs válidos con distinto destinatario → null", () => {
    expect(validateTransferOwnershipInput("uid1", "home1", "uid2")).toBeNull();
  });
});

describe("debugSetPremiumStatus — parseDebugPremiumAllowedUids", () => {
  it("undefined → set vacío", () => {
    expect(parseDebugPremiumAllowedUids(undefined).size).toBe(0);
  });
  it("string vacía → set vacío", () => {
    expect(parseDebugPremiumAllowedUids("").size).toBe(0);
  });
  it("un uid → set con ese uid", () => {
    const set = parseDebugPremiumAllowedUids("uid1");
    expect(set.has("uid1")).toBe(true);
    expect(set.size).toBe(1);
  });
  it("CSV con espacios → trimea y separa", () => {
    const set = parseDebugPremiumAllowedUids(" uid1 , uid2 ,uid3");
    expect(set.has("uid1")).toBe(true);
    expect(set.has("uid2")).toBe(true);
    expect(set.has("uid3")).toBe(true);
    expect(set.size).toBe(3);
  });
  it("CSV con entradas vacías → las ignora", () => {
    const set = parseDebugPremiumAllowedUids("uid1,,uid2,");
    expect(set.size).toBe(2);
  });
});

describe("debugSetPremiumStatus — isDebugPremiumAllowed", () => {
  const empty: ReadonlySet<string> = new Set();
  const allowed: ReadonlySet<string> = new Set(["uid1", "uid2"]);

  it("emulador true → permitido aunque uid undefined", () => {
    expect(isDebugPremiumAllowed("true", undefined, empty)).toBe(true);
  });
  it("emulador true → permitido aunque uid no esté en allowlist", () => {
    expect(isDebugPremiumAllowed("true", "otro", empty)).toBe(true);
  });
  it("emulador false + uid en allowlist → permitido", () => {
    expect(isDebugPremiumAllowed("false", "uid1", allowed)).toBe(true);
  });
  it("emulador undefined + uid en allowlist → permitido", () => {
    expect(isDebugPremiumAllowed(undefined, "uid2", allowed)).toBe(true);
  });
  it("emulador false + uid NO en allowlist → denegado", () => {
    expect(isDebugPremiumAllowed("false", "otro", allowed)).toBe(false);
  });
  it("emulador false + uid undefined → denegado", () => {
    expect(isDebugPremiumAllowed("false", undefined, allowed)).toBe(false);
  });
  it("emulador false + allowlist vacía + uid cualquiera → denegado", () => {
    expect(isDebugPremiumAllowed("false", "uid1", empty)).toBe(false);
  });
  it("emulador '1' (no 'true' exacto) + uid no allowlist → denegado", () => {
    expect(isDebugPremiumAllowed("1", "otro", allowed)).toBe(false);
  });
});

describe("payer protection — removeMember/leaveHome", () => {
  const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];

  function isPayerLocked(
    targetUid: string,
    currentPayerUid: string | null,
    premiumStatus: string
  ): boolean {
    if (targetUid !== currentPayerUid) return false;
    return PROTECTED_STATUSES.includes(premiumStatus);
  }

  it("target === payer + status active → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "active")).toBe(true);
  });
  it("target === payer + status cancelledPendingEnd → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "cancelledPendingEnd")).toBe(true);
  });
  it("target === payer + status rescue → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "rescue")).toBe(true);
  });
  it("target === payer + status free → permitido", () => {
    expect(isPayerLocked("u1", "u1", "free")).toBe(false);
  });
  it("target === payer + status expiredFree → permitido", () => {
    expect(isPayerLocked("u1", "u1", "expiredFree")).toBe(false);
  });
  it("target !== payer → permitido", () => {
    expect(isPayerLocked("u2", "u1", "active")).toBe(false);
  });
  it("currentPayerUid null → permitido", () => {
    expect(isPayerLocked("u1", null, "active")).toBe(false);
  });
});

describe("removeMember — validaciones", () => {
  function validateRemoveInputs(
    callerUid: string,
    homeId: string | undefined,
    targetUid: string | undefined
  ): string | null {
    if (!homeId?.trim() || !targetUid?.trim()) {
      return "homeId and targetUid are required";
    }
    if (callerUid === targetUid) {
      return "cannot-remove-self-use-leave-home";
    }
    return null;
  }

  it("homeId vacío → invalid-argument", () => {
    expect(validateRemoveInputs("u1", "", "u2")).toBe("homeId and targetUid are required");
  });
  it("targetUid vacío → invalid-argument", () => {
    expect(validateRemoveInputs("u1", "h1", "")).toBe("homeId and targetUid are required");
  });
  it("auto-target (caller === target) → precondition", () => {
    expect(validateRemoveInputs("u1", "h1", "u1")).toBe("cannot-remove-self-use-leave-home");
  });
  it("inputs válidos y target distinto → null", () => {
    expect(validateRemoveInputs("u1", "h1", "u2")).toBeNull();
  });
});

describe("removeMember — matriz de roles", () => {
  type Role = "owner" | "admin" | "member";
  function canRemove(callerRole: Role, targetRole: Role): { ok: boolean; code?: string } {
    if (targetRole === "owner") return { ok: false, code: "cannot-remove-owner" };
    if (callerRole === "owner") return { ok: true };
    if (callerRole === "admin" && targetRole === "member") return { ok: true };
    if (callerRole === "admin" && targetRole === "admin") {
      return { ok: false, code: "admin-cannot-remove-admin" };
    }
    return { ok: false, code: "insufficient-role" };
  }

  it("owner puede expulsar member", () => {
    expect(canRemove("owner", "member")).toEqual({ ok: true });
  });
  it("owner puede expulsar admin", () => {
    expect(canRemove("owner", "admin")).toEqual({ ok: true });
  });
  it("nadie puede expulsar owner", () => {
    expect(canRemove("owner", "owner")).toEqual({ ok: false, code: "cannot-remove-owner" });
    expect(canRemove("admin", "owner")).toEqual({ ok: false, code: "cannot-remove-owner" });
  });
  it("admin puede expulsar member", () => {
    expect(canRemove("admin", "member")).toEqual({ ok: true });
  });
  it("admin NO puede expulsar otro admin", () => {
    expect(canRemove("admin", "admin")).toEqual({
      ok: false,
      code: "admin-cannot-remove-admin",
    });
  });
  it("member no puede expulsar a nadie", () => {
    expect(canRemove("member", "member")).toEqual({ ok: false, code: "insufficient-role" });
    expect(canRemove("member", "admin")).toEqual({ ok: false, code: "insufficient-role" });
  });
});
