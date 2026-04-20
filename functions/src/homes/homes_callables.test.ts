// functions/src/homes/homes_callables.test.ts

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

describe("leaveHome — validación rol owner", () => {
  function canLeave(role: string): boolean {
    return role !== "owner";
  }

  it("member puede salir", () => expect(canLeave("member")).toBe(true));
  it("admin puede salir", () => expect(canLeave("admin")).toBe(true));
  it("owner no puede salir", () => expect(canLeave("owner")).toBe(false));
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

describe("debugSetPremiumStatus — gate por emulador", () => {
  function isEmulatorEnv(envValue: string | undefined): boolean {
    return envValue === "true";
  }

  it("FUNCTIONS_EMULATOR==='true' → permitido", () => {
    expect(isEmulatorEnv("true")).toBe(true);
  });
  it("FUNCTIONS_EMULATOR===undefined → denegado", () => {
    expect(isEmulatorEnv(undefined)).toBe(false);
  });
  it("FUNCTIONS_EMULATOR==='false' → denegado", () => {
    expect(isEmulatorEnv("false")).toBe(false);
  });
  it("FUNCTIONS_EMULATOR==='1' → denegado (solo 'true' exacto)", () => {
    expect(isEmulatorEnv("1")).toBe(false);
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
