// functions/src/tasks/manual_reassign.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const manualReassign = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, newAssigneeUid, reason } = request.data as {
    homeId: string;
    taskId: string;
    newAssigneeUid: string;
    reason?: string;
  };
  const callerUid = request.auth.uid;

  if (!homeId || !taskId || !newAssigneeUid) {
    throw new HttpsError("invalid-argument", "homeId, taskId, newAssigneeUid required");
  }

  // Validar que el caller es admin u owner
  const callerRef = db.collection("homes").doc(homeId).collection("members").doc(callerUid);
  const callerSnap = await callerRef.get();
  if (!callerSnap.exists) {
    throw new HttpsError("permission-denied", "Not a member of this home");
  }
  const callerRole = callerSnap.data()!["role"] as string;
  if (callerRole !== "admin" && callerRole !== "owner") {
    throw new HttpsError("permission-denied", "Only admins can manually reassign");
  }

  await db.runTransaction(async (tx) => {
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    // Validar que newAssigneeUid es miembro activo del hogar
    const newAssigneeRef = db
      .collection("homes")
      .doc(homeId)
      .collection("members")
      .doc(newAssigneeUid);
    const newAssigneeSnap = await tx.get(newAssigneeRef);

    if (!newAssigneeSnap.exists) {
      throw new HttpsError("not-found", "new-assignee-not-in-home");
    }
    const newAssigneeStatus = newAssigneeSnap.data()?.["status"] as string | undefined;
    if (newAssigneeStatus !== "active") {
      throw new HttpsError("failed-precondition", "new-assignee-not-active");
    }

    const task = taskSnap.data()!;
    const previousUid = task["currentAssigneeUid"] as string;

    // Evento auditable
    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "manual_reassign",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: callerUid,
      fromUid: previousUid,
      toUid: newAssigneeUid,
      reason: reason ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(taskRef, {
      currentAssigneeUid: newAssigneeUid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info(`manualReassign: task ${taskId} reassigned to ${newAssigneeUid} by ${callerUid}`);
  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Dashboard update failed after manual reassign", err)
  );

  return { success: true };
});
