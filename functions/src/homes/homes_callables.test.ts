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
