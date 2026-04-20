// functions/src/entitlement/slot_ledger.ts
import type { Firestore, Transaction } from "firebase-admin/firestore";
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

/**
 * Variante de `unlockSlotIfEligible` que se ejecuta dentro de una transacción
 * existente (no abre una propia). Pensada para usarse desde `syncEntitlement`,
 * donde el registro del charge y el unlock deben ser atómicos entre sí para
 * evitar condiciones de carrera con el mismo chargeId en paralelo.
 */
export async function unlockSlotIfEligibleTx(
  tx: Transaction,
  firestore: Firestore,
  uid: string,
  chargeId: string,
): Promise<boolean> {
  const userRef = firestore.collection("users").doc(uid);
  const userSnap = await tx.get(userRef);
  const current =
    (userSnap.data()?.["lifetimeUnlockedHomeSlots"] as number | undefined) ?? 0;

  if (current >= 3) {
    return false;
  }

  tx.update(userRef, {
    lifetimeUnlockedHomeSlots: FieldValue.increment(1),
    homeSlotCap: FieldValue.increment(1),
    lastUnlockedChargeId: chargeId,
    lastUnlockedAt: FieldValue.serverTimestamp(),
  });
  return true;
}
