// functions/src/tasks/apply_task_completion.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";
import {
  MemberLoadData,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  addRecurrenceInterval,
  isTerminalRecurrence,
} from "./task_assignment_helpers";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const applyTaskCompletion = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId } = request.data as { homeId: string; taskId: string };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  const result = await db.runTransaction(async (tx) => {
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnap.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    // Leer miembros para conocer excluidos (frozen + absent) y load data
    const membersSnap = await tx.get(
      db.collection("homes").doc(homeId).collection("members")
    );
    const excludedUids: string[] = [];
    const loadDataMap = new Map<string, MemberLoadData>();

    for (const mDoc of membersSnap.docs) {
      const mData = mDoc.data();
      if (mData["status"] === "frozen" || mData["status"] === "absent") {
        excludedUids.push(mDoc.id);
      }
      const completions60d: number = (mData["completions60d"] as number) ?? 0;
      const lastCompletedAt: admin.firestore.Timestamp | undefined = mData["lastCompletedAt"];
      const daysSince = lastCompletedAt
        ? Math.floor((Date.now() - lastCompletedAt.toMillis()) / (1000 * 60 * 60 * 24))
        : 0;
      loadDataMap.set(mDoc.id, {
        completionsRecent: completions60d,
        difficultyWeight: 1.0,
        daysSinceLastExecution: daysSince,
      });
    }

    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const frozenUids: string[] = task["frozenUids"] ?? [];
    const allExcluded = [...new Set([...frozenUids, ...excludedUids])];
    const distributionMode: string = task["distributionMode"] ?? "round_robin";

    let nextAssigneeUid: string;
    if (distributionMode === "smart") {
      nextAssigneeUid = getNextAssigneeSmart(assignmentOrder, uid, allExcluded, loadDataMap);
    } else {
      nextAssigneeUid = getNextAssigneeRoundRobin(assignmentOrder, uid, allExcluded) ?? uid;
    }

    const currentDue = (task["nextDueAt"] as admin.firestore.Timestamp | undefined)
      ?.toDate() ?? admin.firestore.Timestamp.now().toDate();
    const recurrenceType: string = task["recurrenceType"] ?? "daily";
    const isOneTime = isTerminalRecurrence(recurrenceType);
    const nextDueAt = addRecurrenceInterval(currentDue, recurrenceType);

    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "completed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      performerUid: uid,
      completedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: false,
    });

    // Tarea puntual: al completarla deja de contar como activa y no vuelve a
    // aparecer en el dashboard. Conservamos nextDueAt para que el historial
    // muestre la fecha original del evento.
    const taskUpdate: Record<string, unknown> = {
      currentAssigneeUid: isOneTime ? null : nextAssigneeUid,
      nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
      completedCount90d: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (isOneTime) {
      taskUpdate["status"] = "completedOneTime";
    }
    tx.update(taskRef, taskUpdate);

    // Usamos el snapshot ya leído de membersSnap para evitar read-after-write en la transacción
    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberDocInSnap = membersSnap.docs.find((d) => d.id === uid);
    const member = memberDocInSnap?.data() ?? {};
    const newCompleted = ((member["tasksCompleted"] as number) ?? 0) + 1;
    const newPassed: number = (member["passedCount"] as number) ?? 0;
    const newCompliance = newCompleted / (newCompleted + newPassed);

    // Calcular currentStreak
    const lastCompletedAt: admin.firestore.Timestamp | undefined = member["lastCompletedAt"];
    const now = admin.firestore.Timestamp.now().toDate();
    let newStreak: number | ReturnType<typeof FieldValue.increment>;
    if (lastCompletedAt) {
      const last = lastCompletedAt.toDate();
      const daysDiff = Math.floor(
        (Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()) -
          Date.UTC(last.getFullYear(), last.getMonth(), last.getDate())) /
          (1000 * 60 * 60 * 24)
      );
      if (daysDiff === 0) {
        // Misma jornada: mantener el streak existente, pero al menos 1
        const existingStreak = (member["currentStreak"] as number) ?? 0;
        newStreak = Math.max(existingStreak, 1);
      } else if (daysDiff === 1) {
        // Día consecutivo: incrementar
        newStreak = FieldValue.increment(1);
      } else {
        // Racha rota: reiniciar
        newStreak = 1;
      }
    } else {
      // Primera vez: streak = 1
      newStreak = 1;
    }

    tx.update(memberRef, {
      tasksCompleted: FieldValue.increment(1),
      completions60d: FieldValue.increment(1),
      complianceRate: newCompliance,
      currentStreak: newStreak,
      lastCompletedAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return { eventId: eventRef.id, nextAssigneeUid };
  });

  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Failed to update dashboard after completion", err)
  );

  return result;
});
