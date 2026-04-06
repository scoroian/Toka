// functions/src/entitlement/slot_ledger.test.ts
import { unlockSlotIfEligible } from "./slot_ledger";

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
