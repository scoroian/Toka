// functions/src/tasks/pass_task_turn.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";
import { sendPassNotification } from "../notifications/send_pass_notification";
import { getNextEligibleMember } from "./pass_turn_helpers";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

/**
 * Callable `passTaskTurn` — BUG-06.
 *
 * Pasar turno es una acción EXPLÍCITA del usuario: siempre avanza en
 * `assignmentOrder` usando {@link getNextEligibleMember}. No consulta
 * `onMissAssign`, que solo rige el cron `processExpiredTasks`
 * (tarea vencida sin acción → `computeNextAssignee(onMissAssign, ...)`).
 *
 * Con 2 miembros + `onMissAssign=sameAssignee`, pasar turno alterna A ↔ B.
 */
export const passTaskTurn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, reason } = request.data as {
    homeId: string;
    taskId: string;
    reason?: string;
  };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  const taskSnap = await db.collection("homes").doc(homeId).collection("tasks").doc(taskId).get();
  const taskTitle: string = taskSnap.data()?.["title"] ?? "";

  const result = await db.runTransaction(async (tx) => {
    // 1. Leer tarea y validar
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnapTx = await tx.get(taskRef);
    if (!taskSnapTx.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnapTx.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    // 2. Leer miembros para conocer congelados/ausentes
    const membersSnap = await tx.get(
      db.collection("homes").doc(homeId).collection("members")
    );
    const frozenUids: string[] = [];
    for (const mDoc of membersSnap.docs) {
      const mData = mDoc.data();
      if (mData["status"] === "frozen" || mData["status"] === "absent") {
        frozenUids.push(mDoc.id);
      }
    }

    // 3. Encontrar siguiente elegible
    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const toUid = getNextEligibleMember(assignmentOrder, uid, frozenUids);
    const noCandidate = toUid === uid;

    // 4. Calcular compliance antes y después
    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const legacyCompleted = (member["tasksCompleted"] as number | undefined) ?? 0;
    const completed: number = (member["completedCount"] as number | undefined) ?? legacyCompleted;
    const passed: number = (member["passedCount"] as number) ?? 0;
    const complianceBefore = completed / Math.max(completed + passed, 1);
    const complianceAfter = completed / Math.max(completed + passed + 1, 1);

    // 5. Crear evento passed en taskEvents
    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "passed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      toUid,
      reason: reason ?? null,
      noCandidate,
      complianceBefore,
      complianceAfter,
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: true,
    });

    // 6. Actualizar tarea
    tx.update(taskRef, {
      currentAssigneeUid: toUid,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 7. Actualizar contadores del miembro que pasa
    tx.update(memberRef, {
      completedCount: completed,
      tasksCompleted: FieldValue.delete(),
      passedCount: FieldValue.increment(1),
      complianceRate: complianceAfter,
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return { toUid, noCandidate, complianceBefore, complianceAfter };
  });

  // Actualizar dashboard
  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Failed to update dashboard after pass", err)
  );

  if (!result.noCandidate) {
    sendPassNotification(homeId, taskId, taskTitle, result.toUid, uid).catch((err) =>
      logger.warn("sendPassNotification failed", err)
    );
  }

  return result;
});
