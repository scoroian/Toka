// functions/src/entitlement/slot_ledger.ts
import type {
  Firestore,
  Transaction,
  DocumentReference,
} from "firebase-admin/firestore";
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
  return applySlotUnlockTx(tx, userRef, userSnap.data(), chargeId);
}

/**
 * Aplica el unlock de plaza SIN hacer ninguna lectura (write-only). El caller
 * debe pasar los datos del usuario ya leídos (`userData`).
 *
 * Firestore exige que TODAS las lecturas de una transacción ocurran antes de
 * cualquier escritura. `syncEntitlement` lee `users/{uid}`, `homes/{homeId}` y
 * el doc del charge por adelantado y luego invoca esta función — así el unlock
 * no introduce una lectura-después-de-escritura que rompería la transacción.
 */
export function applySlotUnlockTx(
  tx: Transaction,
  userRef: DocumentReference,
  userData: Record<string, unknown> | undefined,
  chargeId: string,
): boolean {
  const current = readUnlockedSlots(userData);
  if (current >= 3) {
    return false;
  }

  const nextUnlocked = current + 1;
  const baseHomeSlots = readBaseSlots(userData);
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

/**
 * Revoca la plaza concedida por un `chargeId` (reembolso / chargeback / revoke
 * de la store). Es la operación inversa de `applySlotUnlockTx`:
 *  - marca el doc del ledger con `validForUnlock=false` (+ `revokedAt`/motivo),
 *  - decrementa `lifetimeUnlockedHomeSlots` (suelo en 0) y recalcula
 *    `homeSlotCap` = base + plazas restantes.
 *
 * Idempotente: si el ledger no existe o ya estaba revocado, no hace nada y
 * devuelve `false`. WRITE-ONLY: el caller debe pasar `userData` y `ledgerSnap`
 * ya leídos dentro de la misma transacción (Firestore exige lecturas antes que
 * escrituras).
 */
export function applySlotRevokeTx(
  tx: Transaction,
  userRef: DocumentReference,
  userData: Record<string, unknown> | undefined,
  ledgerSnap: { exists: boolean; data: () => Record<string, unknown> | undefined },
  chargeId: string,
  reason: string,
): boolean {
  if (!ledgerSnap.exists) {
    return false; // nunca se concedió plaza por este cargo
  }
  const ledgerData = ledgerSnap.data();
  if (ledgerData?.["validForUnlock"] === false) {
    return false; // ya revocada → idempotente
  }

  const current = readUnlockedSlots(userData);
  const nextUnlocked = Math.max(0, current - 1);
  const baseHomeSlots = readBaseSlots(userData);
  const ledgerRef = userRef.collection("slotLedger").doc(chargeId);

  tx.update(userRef, {
    baseHomeSlots,
    lifetimeUnlockedHomeSlots: nextUnlocked,
    homeSlotCap: baseHomeSlots + nextUnlocked,
    // limpiar/neutralizar campos legacy si existen
    lifetimeUnlocked: FieldValue.delete(),
    baseSlots: FieldValue.delete(),
    lastRevokedChargeId: chargeId,
    lastRevokedAt: FieldValue.serverTimestamp(),
  });
  tx.set(
    ledgerRef,
    {
      validForUnlock: false,
      revokedAt: FieldValue.serverTimestamp(),
      revokeReason: reason,
    },
    { merge: true },
  );
  return true;
}

/**
 * Variante standalone de `applySlotRevokeTx` que abre su propia transacción.
 * Útil para flujos que solo necesitan revocar la plaza (sin tocar el hogar).
 */
export async function revokeSlotForCharge(
  db: Firestore,
  uid: string,
  chargeId: string,
  reason: string,
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const userRef = db.collection("users").doc(uid);
    const ledgerRef = userRef.collection("slotLedger").doc(chargeId);
    const [userSnap, ledgerSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(ledgerRef),
    ]);
    return applySlotRevokeTx(
      tx,
      userRef,
      userSnap.data(),
      ledgerSnap,
      chargeId,
      reason,
    );
  });
}
