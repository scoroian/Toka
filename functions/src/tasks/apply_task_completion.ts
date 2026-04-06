// functions/src/tasks/apply_task_completion.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

interface MemberLoadData {
  completionsRecent: number;
  difficultyWeight: number;
  daysSinceLastExecution: number;
}

function scoreOf(data: MemberLoadData): number {
  return data.completionsRecent * data.difficultyWeight + data.daysSinceLastExecution * -0.1;
}

function getNextAssigneeRoundRobin(
  order: string[],
  currentUid: string,
  excludedUids: string[]
): string | null {
  if (!order.length) return null;
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  const idx = eligible.indexOf(currentUid);
  const nextIdx = (idx + 1) % eligible.length;
  return eligible[nextIdx];
}

function getNextAssigneeSmart(
  order: string[],
  currentUid: string,
  excludedUids: string[],
  loadData: Map<string, MemberLoadData>
): string {
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  return eligible.reduce((a, b) => {
    const aData = loadData.get(a) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    const bData = loadData.get(b) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    return scoreOf(aData) <= scoreOf(bData) ? a : b;
  });
}

function addRecurrenceInterval(base: Date, recurrenceType: string): Date {
  const d = new Date(base);
  switch (recurrenceType) {
    case "hourly":  d.setHours(d.getHours() + 1); break;
    case "daily":   d.setDate(d.getDate() + 1); break;
    case "weekly":  d.setDate(d.getDate() + 7); break;
    case "monthly": d.setMonth(d.getMonth() + 1); break;
    case "yearly":  d.setFullYear(d.getFullYear() + 1); break;
  }
  return d;
}

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
      ?.toDate() ?? new Date();
    const recurrenceType: string = task["recurrenceType"] ?? "daily";
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

    tx.update(taskRef, {
      currentAssigneeUid: nextAssigneeUid,
      nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
      completedCount90d: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const newCompleted = ((member["completedCount"] as number) ?? 0) + 1;
    const newPassed: number = (member["passedCount"] as number) ?? 0;
    const newCompliance = newCompleted / (newCompleted + newPassed);

    tx.update(memberRef, {
      completedCount: FieldValue.increment(1),
      completions60d: FieldValue.increment(1),
      complianceRate: newCompliance,
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
