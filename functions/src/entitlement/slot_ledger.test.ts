// functions/src/entitlement/slot_ledger.test.ts
import { unlockSlotIfEligible, revokeSlotForCharge } from "./slot_ledger";

/**
 * Builds a minimal Firestore-like mock that supports the two paths used by
 * unlockSlotIfEligible:
 *   - users/{uid}                        (userRef)
 *   - users/{uid}/slotLedger/{chargeId}  (ledgerRef)
 *
 * The transaction's `get` is called twice in this order:
 *   1st call → ledgerSnap
 *   2nd call → userSnap
 */
function makeDb(lifetimeSlots: number, ledgerHasCharge: boolean) {
  const ledgerSnap = { exists: ledgerHasCharge };
  const userSnap = {
    exists: true,
    data: () => ({
      lifetimeUnlockedHomeSlots: lifetimeSlots,
      homeSlotCap: lifetimeSlots + 2,
    }),
  };

  // Pre-built ref objects (no recursive construction)
  const ledgerRef = { _type: "ledgerRef" };
  const userRef = { _type: "userRef" };

  // Transaction mock: get returns snaps in call order
  const txGet = jest.fn()
    .mockResolvedValueOnce(ledgerSnap)
    .mockResolvedValueOnce(userSnap);
  const txUpdate = jest.fn();
  const txSet = jest.fn();
  const txMock = { get: txGet, update: txUpdate, set: txSet };

  // db.collection("users").doc(uid) → userRef
  // db.collection("users").doc(uid).collection("slotLedger").doc(chargeId) → ledgerRef
  const slotLedgerCollection = { doc: jest.fn().mockReturnValue(ledgerRef) };
  const userDocObj = {
    ...userRef,
    collection: jest.fn().mockReturnValue(slotLedgerCollection),
  };
  const usersCollection = { doc: jest.fn().mockReturnValue(userDocObj) };

  const db = {
    runTransaction: jest.fn().mockImplementation(
      async (fn: (tx: typeof txMock) => Promise<unknown>) => fn(txMock)
    ),
    collection: jest.fn().mockReturnValue(usersCollection),
  };

  return { db, txUpdate, txSet };
}

describe("unlockSlotIfEligible", () => {
  it("retorna false si lifetimeUnlockedHomeSlots >= 3", async () => {
    const { db } = makeDb(3, false);
    const result = await unlockSlotIfEligible(db as any, "uid1", "charge-001");
    expect(result).toBe(false);
  });

  it("retorna false si el chargeId ya fue procesado (idempotencia)", async () => {
    const { db } = makeDb(1, true); // ledgerHasCharge=true → primera get devuelve exists:true
    const result = await unlockSlotIfEligible(db as any, "uid1", "charge-already-seen");
    expect(result).toBe(false);
  });

  it("retorna true si lifetimeSlots < 3 y chargeId es nuevo", async () => {
    const { db, txUpdate, txSet } = makeDb(0, false);
    const result = await unlockSlotIfEligible(db as any, "uid1", "charge-new");
    expect(result).toBe(true);
    expect(txUpdate).toHaveBeenCalledTimes(1);
    expect(txSet).toHaveBeenCalledTimes(1);
  });

  it("retorna true con lifetimeSlots = 2 (2 < 3, debe desbloquear)", async () => {
    const { db } = makeDb(2, false);
    const result = await unlockSlotIfEligible(db as any, "uid1", "charge-new");
    expect(result).toBe(true);
  });
});

/**
 * Mock para revokeSlotForCharge: lee userRef y ledgerRef vía Promise.all en
 * ese orden (1ª get → userSnap, 2ª get → ledgerSnap).
 */
function makeRevokeDb(
  lifetimeSlots: number,
  ledger: { exists: boolean; validForUnlock?: boolean },
) {
  const userSnap = {
    exists: true,
    data: () => ({
      lifetimeUnlockedHomeSlots: lifetimeSlots,
      baseHomeSlots: 2,
      homeSlotCap: lifetimeSlots + 2,
    }),
  };
  const ledgerSnap = {
    exists: ledger.exists,
    data: () =>
      ledger.exists ? { validForUnlock: ledger.validForUnlock ?? true } : undefined,
  };

  const ledgerRef = { _type: "ledgerRef" };
  const userRef = {
    _type: "userRef",
    collection: jest.fn().mockReturnValue({ doc: jest.fn().mockReturnValue(ledgerRef) }),
  };

  const txGet = jest.fn()
    .mockResolvedValueOnce(userSnap)
    .mockResolvedValueOnce(ledgerSnap);
  const txUpdate = jest.fn();
  const txSet = jest.fn();
  const txMock = { get: txGet, update: txUpdate, set: txSet };

  const usersCollection = { doc: jest.fn().mockReturnValue(userRef) };
  const db = {
    runTransaction: jest.fn().mockImplementation(
      async (fn: (tx: typeof txMock) => Promise<unknown>) => fn(txMock)
    ),
    collection: jest.fn().mockReturnValue(usersCollection),
  };
  return { db, txUpdate, txSet };
}

describe("revokeSlotForCharge", () => {
  it("revoca una plaza concedida: decrementa el contador y marca el ledger", async () => {
    const { db, txUpdate, txSet } = makeRevokeDb(2, { exists: true, validForUnlock: true });
    const result = await revokeSlotForCharge(db as any, "uid1", "charge-001", "refund");
    expect(result).toBe(true);
    // user.update con lifetimeUnlockedHomeSlots = 1 y homeSlotCap = base + 1
    expect(txUpdate).toHaveBeenCalledTimes(1);
    const updateArg = txUpdate.mock.calls[0][1];
    expect(updateArg.lifetimeUnlockedHomeSlots).toBe(1);
    expect(updateArg.homeSlotCap).toBe(3);
    // ledger.set con validForUnlock=false (merge)
    expect(txSet).toHaveBeenCalledTimes(1);
    expect(txSet.mock.calls[0][1].validForUnlock).toBe(false);
  });

  it("suelo en 0: no baja de cero aunque el contador esté en 0", async () => {
    const { db, txUpdate } = makeRevokeDb(0, { exists: true, validForUnlock: true });
    const result = await revokeSlotForCharge(db as any, "uid1", "charge-001", "refund");
    expect(result).toBe(true);
    expect(txUpdate.mock.calls[0][1].lifetimeUnlockedHomeSlots).toBe(0);
  });

  it("idempotente: ledger ya revocado → no escribe y retorna false", async () => {
    const { db, txUpdate, txSet } = makeRevokeDb(1, { exists: true, validForUnlock: false });
    const result = await revokeSlotForCharge(db as any, "uid1", "charge-001", "refund");
    expect(result).toBe(false);
    expect(txUpdate).not.toHaveBeenCalled();
    expect(txSet).not.toHaveBeenCalled();
  });

  it("sin ledger (plaza nunca concedida) → no escribe y retorna false", async () => {
    const { db, txUpdate, txSet } = makeRevokeDb(1, { exists: false });
    const result = await revokeSlotForCharge(db as any, "uid1", "charge-404", "refund");
    expect(result).toBe(false);
    expect(txUpdate).not.toHaveBeenCalled();
    expect(txSet).not.toHaveBeenCalled();
  });
});
