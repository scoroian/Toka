// functions/src/entitlement/slot_ledger.ts
import type { Firestore, Transaction } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";

function readUnlockedSlots(data: Record<string, unknown> | undefined): number {
  return (data?.["lifetimeUnlockedHomeSlots"] as number | undefined) ??
    (data?.["lifetimeUnlocked"] as number | undefined) ??
    0;
}

function readBaseSlots(data: Record<string, unknown> | undefined): number {
  return (data?.["baseHomeSlots"] as number | undefined) ??
    (data?.["baseSlots"] as number | undefined) ??
    2;
}

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
    const current = readUnlockedSlots(data);
    if (current >= 3) return false;

    const nextUnlocked = current + 1;
    const baseHomeSlots = readBaseSlots(data);
    tx.update(userRef, {
      baseHomeSlots,
      lifetimeUnlockedHomeSlots: nextUnlocked,
      homeSlotCap: baseHomeSlots + nextUnlocked,
      // limpiar/neutralizar campos legacy si existen
      lifetimeUnlocked: FieldValue.delete(),
      baseSlots: FieldValue.delete(),
      lastUnlockedChargeId: chargeId,
      lastUnlockedAt: FieldValue.serverTimestamp(),
    });
    tx.set(ledgerRef, {
      sourceType: "premium_purchase",
      sourceChargeId: chargeId,
      chargeId,
      validForUnlock: true,
      slotNumber: nextUnlocked,
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
  const data = userSnap.data() as Record<string, unknown> | undefined;
  const current = readUnlockedSlots(data);

  if (current >= 3) {
    return false;
  }

  const nextUnlocked = current + 1;
  const baseHomeSlots = readBaseSlots(data);
  const ledgerRef = userRef.collection("slotLedger").doc(chargeId);

  tx.update(userRef, {
    baseHomeSlots,
    lifetimeUnlockedHomeSlots: nextUnlocked,
    homeSlotCap: baseHomeSlots + nextUnlocked,
    // limpiar/neutralizar campos legacy si existen
    lifetimeUnlocked: FieldValue.delete(),
    baseSlots: FieldValue.delete(),
    lastUnlockedChargeId: chargeId,
    lastUnlockedAt: FieldValue.serverTimestamp(),
  });
  tx.set(ledgerRef, {
    sourceType: "premium_purchase",
    sourceChargeId: chargeId,
    chargeId,
    validForUnlock: true,
    slotNumber: nextUnlocked,
    unlockedAt: FieldValue.serverTimestamp(),
  });
  return true;
}
