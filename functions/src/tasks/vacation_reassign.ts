// functions/src/tasks/vacation_reassign.ts
//
// Hallazgo #09 — Vacaciones.
//
// Cuando un miembro inicia una vacación (el cliente escribe el campo `vacation`
// en su documento de miembro), sus tareas activas NO deben quedarse pegadas a él
// para vencer durante la ausencia (lo que dispararía la penalización del cron).
// Este trigger detecta la TRANSICIÓN a "ausente" y reasigna esas tareas al
// siguiente miembro presente, MANTENIENDO al ausente en `assignmentOrder` (para
// que vuelva a la rotación al regresar — su ausencia se recalcula en vivo).
//
// Defensa en profundidad: el cron `processExpiredTasks` también evita penalizar
// a un ausente y rueda la tarea (cubre vacaciones con fecha de inicio futura, que
// no producen un write del doc de miembro al activarse).

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { getNextEligibleMember } from "./pass_turn_helpers";
import { isMemberCurrentlyAbsent } from "../shared/vacation";
import { updateHomeDashboard } from "./update_dashboard";

/**
 * Reasigna las tareas activas cuyo responsable actual es `absentUid` a un
 * miembro PRESENTE (no congelado / no ausente / no ex-miembro), conservando el
 * `assignmentOrder` intacto. Best-effort por tarea.
 *
 * @returns nº de tareas efectivamente reasignadas (0 si no había heredero
 *   disponible o el ausente no era responsable de ninguna tarea activa).
 */
export async function reassignActiveTasksForAbsentMember(
  homeId: string,
  absentUid: string
): Promise<number> {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;

  // Conjunto de excluidos del reparto: ex-miembros, congelados y ausentes.
  const membersSnap = await db
    .collection("homes").doc(homeId).collection("members").get();
  const excludedUids: string[] = [];
  for (const mDoc of membersSnap.docs) {
    const md = mDoc.data();
    if (
      md["status"] === "left" ||
      md["status"] === "frozen" ||
      isMemberCurrentlyAbsent(md)
    ) {
      excludedUids.push(mDoc.id);
    }
  }

  // Tareas activas del hogar (cap pequeño por hogar). Filtramos en memoria por
  // responsable actual para no exigir un índice compuesto.
  const tasksSnap = await db
    .collection("homes").doc(homeId).collection("tasks")
    .where("status", "==", "active")
    .get();

  let reassigned = 0;
  for (const taskDoc of tasksSnap.docs) {
    const task = taskDoc.data();
    if (task["currentAssigneeUid"] !== absentUid) continue;

    const order: string[] = task["assignmentOrder"] ?? [absentUid];
    const toUid = getNextEligibleMember(order, absentUid, excludedUids);
    if (toUid === absentUid) continue; // nadie disponible → se queda en el ausente

    await taskDoc.ref.update({
      currentAssigneeUid: toUid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    reassigned++;
  }
  return reassigned;
}

/**
 * Trigger Firestore: al actualizarse el documento de un miembro, si su vacación
 * pasa a estar ACTIVA-AHORA (transición), reasigna sus tareas activas a miembros
 * presentes y reconstruye el dashboard. Solo actúa en la transición para no
 * repetir trabajo en cada write del doc de miembro.
 */
export const onMemberVacationStart = onDocumentWritten(
  "homes/{homeId}/members/{memberId}",
  async (event) => {
    const homeId = event.params.homeId as string;
    const memberId = event.params.memberId as string;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return; // doc borrado: nada que reasignar

    const wasAbsent = isMemberCurrentlyAbsent(before);
    const isAbsent = isMemberCurrentlyAbsent(after);
    if (!isAbsent || wasAbsent) return; // solo en la transición presente→ausente

    try {
      const n = await reassignActiveTasksForAbsentMember(homeId, memberId);
      if (n > 0) {
        await updateHomeDashboard(homeId);
        logger.info(
          `onMemberVacationStart: reasignadas ${n} tarea(s) de ${memberId} ` +
            `en hogar ${homeId} al iniciar vacación`
        );
      }
    } catch (err) {
      logger.error(
        `onMemberVacationStart: fallo reasignando tareas de ${memberId} ` +
          `en hogar ${homeId}`,
        err
      );
    }
  }
);
