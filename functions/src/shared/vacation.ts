// functions/src/shared/vacation.ts
import * as admin from "firebase-admin";

/**
 * Indica si un miembro debe EXCLUIRSE del reparto de tareas por AUSENCIA.
 *
 * Es true cuando el miembro tiene una vacación activa (`vacation.isActive ===
 * true`) cuyo rango de fechas incluye HOY. `startDate` es inclusivo desde su
 * 00:00; `endDate` es inclusivo durante TODO su día (se suma 24 h). Fechas nulas
 * = sin límite por ese extremo.
 *
 * El campo `vacation` (que persiste el cliente) es la ÚNICA fuente de verdad: no
 * dependemos de un `status: 'absent'` denormalizado (que las Firestore rules no
 * dejan escribir al cliente y quedaría stale). Las tareas congeladas
 * (`status === "frozen"`) se tratan por separado en cada caller.
 */
export function isMemberCurrentlyAbsent(
  mData: admin.firestore.DocumentData | undefined,
  nowMs: number = Date.now()
): boolean {
  if (!mData) return false;
  const v = mData["vacation"];
  if (!v || v["isActive"] !== true) return false;
  const start = v["startDate"] as admin.firestore.Timestamp | undefined | null;
  const end = v["endDate"] as admin.firestore.Timestamp | undefined | null;
  if (start && nowMs < start.toMillis()) return false;
  if (end && nowMs > end.toMillis() + 24 * 60 * 60 * 1000) return false;
  return true;
}
