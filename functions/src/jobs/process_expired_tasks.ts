// functions/src/jobs/process_expired_tasks.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { addRecurrenceInterval } from "../tasks/task_assignment_helpers";

// ── Lógica pura (exportada para tests) ───────────────────────────────────────

export function computeNextAssignee(
  onMissAssign: string,
  currentUid: string,
  assignmentOrder: string[],
  frozenUids: string[]
): string {
  if ((onMissAssign ?? "sameAssignee") === "nextInRotation") {
    const eligible = assignmentOrder.filter((u) => !frozenUids.includes(u));
    if (!eligible.length) return currentUid;
    const idx = eligible.indexOf(currentUid);
    return eligible[(idx + 1) % eligible.length];
  }
  return currentUid;
}

export function computeComplianceAfterMiss(
  completedCount: number,
  passedCount: number,
  missedCount: number
): number {
  const total = completedCount + passedCount + missedCount + 1;
  if (total === 0) return 0;
  return completedCount / total;
}

export function isExpired(nextDueAtMs: number, cutoffMs: number): boolean {
  return nextDueAtMs < cutoffMs;
}

// ── Job programado ────────────────────────────────────────────────────────────

/**
 * Cron diario a las 00:05 UTC.
 * Marca como "missed" todas las tareas activas con nextDueAt < medianoche UTC de hoy.
 */
export const processExpiredTasks = onSchedule("5 0 * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;

  // Corte: medianoche UTC del día actual
  const cutoff = admin.firestore.Timestamp.now().toDate();
  cutoff.setUTCHours(0, 0, 0, 0);

  logger.info(`processExpiredTasks: cutoff = ${cutoff.toISOString()}`);

  const snapshot = await db
    .collectionGroup("tasks")
    .where("status", "==", "active")
    .where("nextDueAt", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .limit(100)
    .get();

  if (snapshot.empty) {
    logger.info("processExpiredTasks: no expired tasks found");
    return;
  }

  if (snapshot.size >= 100) {
    logger.warn(
      "processExpiredTasks: reached 100-task limit; remaining tasks will be processed tomorrow"
    );
  }

  logger.info(`processExpiredTasks: processing ${snapshot.size} tasks`);

  const affectedHomeIds = new Set<string>();

  for (const taskDoc of snapshot.docs) {
    // homeId se obtiene del path: homes/{homeId}/tasks/{taskId}
    const pathParts = taskDoc.ref.path.split("/");
    const homeId = pathParts[1];
    const taskId = taskDoc.id;

    try {
      await db.runTransaction(async (tx) => {
        const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
        const taskSnap = await tx.get(taskRef);
        if (!taskSnap.exists) return;

        const task = taskSnap.data()!;

        // Verificación de idempotencia dentro de la transacción
        const taskNextDue: admin.firestore.Timestamp | undefined = task["nextDueAt"];
        if (!taskNextDue || taskNextDue.toMillis() >= cutoff.getTime()) return;
        if (task["status"] !== "active") return;

        const actorUid: string = task["currentAssigneeUid"] ?? "";
        const assignmentOrder: string[] = task["assignmentOrder"] ?? [actorUid];
        const onMissAssign: string = task["onMissAssign"] ?? "sameAssignee";

        // Leer miembros para frozen/absent
        const membersSnap = await tx.get(
          db.collection("homes").doc(homeId).collection("members")
        );
        const frozenUids: string[] = [];
        for (const mDoc of membersSnap.docs) {
          const s = mDoc.data()["status"] as string | undefined;
          if (s === "frozen" || s === "absent") frozenUids.push(mDoc.id);
        }

        const toUid = computeNextAssignee(onMissAssign, actorUid, assignmentOrder, frozenUids);
        const nextDueAt = addRecurrenceInterval(
          taskNextDue.toDate(),
          (task["recurrenceType"] as string | undefined) ?? "daily"
        );

        // Stats del miembro que incumplió
        const memberRef = db.collection("homes").doc(homeId).collection("members").doc(actorUid);
        const memberDocInSnap = membersSnap.docs.find((d) => d.id === actorUid);
        const member = memberDocInSnap?.data() ?? {};
        const completed: number = (member["completedCount"] as number) ?? 0;
        const passed: number    = (member["passedCount"]   as number) ?? 0;
        const missed: number    = (member["missedCount"]   as number) ?? 0;
        const complianceBefore  = completed / Math.max(completed + passed + missed, 1);
        const complianceAfter   = computeComplianceAfterMiss(completed, passed, missed);

        // Evento missed
        const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
        tx.set(eventRef, {
          eventType: "missed",
          taskId,
          taskTitleSnapshot: task["title"] ?? "",
          taskVisualSnapshot: {
            kind: task["visualKind"] ?? "emoji",
            value: task["visualValue"] ?? "",
          },
          actorUid,
          toUid,
          penaltyApplied: true,
          complianceBefore,
          complianceAfter,
          missedAt: taskNextDue,
          createdAt: FieldValue.serverTimestamp(),
        });

        // Actualizar tarea
        tx.update(taskRef, {
          currentAssigneeUid: toUid,
          nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Actualizar miembro
        tx.update(memberRef, {
          missedCount: FieldValue.increment(1),
          complianceRate: complianceAfter,
          lastActiveAt: FieldValue.serverTimestamp(),
        });
      });

      affectedHomeIds.add(homeId);
      logger.info(`processExpiredTasks: processed task ${taskId} in home ${homeId}`);
    } catch (err) {
      logger.error(`processExpiredTasks: error processing task ${taskId}`, err);
    }
  }

  logger.info(`processExpiredTasks: done. Affected homes: ${affectedHomeIds.size}`);
});
