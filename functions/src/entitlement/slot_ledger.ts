// functions/src/entitlement/slot_ledger.ts
import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";

export async function unlockSlotIfEligible(
  db: Firestore,
  uid: string,
  chargeId: string,
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const ledgerRef = db
      .collection("users")
      .doc(uid)
      .collection("slotLedger")
      .doc(chargeId);
    const ledgerSnap = await tx.get(ledgerRef);
    if (ledgerSnap.exists) return false; // idempotencia: ya procesado

    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) return false;

    const data = userSnap.data() as Record<string, unknown>;
    const current = (data["lifetimeUnlockedHomeSlots"] as number) ?? 0;
    if (current >= 3) return false;

    tx.update(userRef, {
      lifetimeUnlockedHomeSlots: FieldValue.increment(1),
      homeSlotCap: FieldValue.increment(1),
    });
    tx.set(ledgerRef, {
      chargeId,
      unlockedAt: FieldValue.serverTimestamp(),
    });

    return true;
  });
}
