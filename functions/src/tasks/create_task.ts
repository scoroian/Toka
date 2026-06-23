// functions/src/tasks/create_task.ts
//
// Callable `createTask` — alta de tareas con enforcement del límite Free
// HECHO EN EL SERVIDOR Y DE FORMA TRANSACCIONAL (Hallazgo #14).
//
// Por qué una callable y no las reglas Firestore:
//   El límite del plan Free ("4 activas + 3 recurrentes automáticas") vivía solo
//   en `firestore.rules` (`freeCanCreateTask`), que leía un contador
//   DENORMALIZADO (`views/dashboard.planCounters.activeTasks`) reconstruido de
//   forma EVENTUAL por el trigger `onTaskWriteUpdateDashboard`. Como las reglas
//   no pueden CONTAR documentos, una ráfaga de altas más rápida que la
//   reconstrucción del dashboard evaluaba todas contra el mismo contador
//   obsoleto < 4 y todas pasaban → el límite era eludible.
//
// Aquí la creación pasa por una transacción que cuenta las tareas ACTIVAS reales
// en el momento. Para que dos altas concurrentes del mismo hogar no puedan ambas
// commitear sobre un conteo obsoleto, la transacción lee+escribe un documento
// ancla (`system/taskGuard`): la segunda transacción entra en contención,
// reintenta, vuelve a contar (ya ve la tarea de la primera) y se rechaza. Las
// escrituras directas de tareas quedan prohibidas en reglas (`allow create: if
// false`), de modo que esta es la única vía de alta.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isPremium, FREE_LIMITS, FREE_LIMIT_CODES } from "../shared/free_limits";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// Recurrencias válidas (espejo de `RecurrenceType` del cliente). Solo `oneTime`
// NO cuenta como recurrente automática; el resto sí.
const VALID_RECURRENCE = new Set(["hourly", "daily", "weekly", "monthly", "yearly", "oneTime"]);

// Payload JSON-safe enviado por el cliente. `nextDueAt` viaja como ISO 8601
// (lo calcula el cliente con `RecurrenceCalculator`, igual que antes cuando
// escribía el documento directamente; no es un campo sensible a seguridad).
interface TaskPayload {
  title: string;
  description?: string | null;
  visualKind: string;
  visualValue: string;
  recurrenceType: string;
  recurrenceRule: Record<string, unknown>;
  assignmentMode: string;
  assignmentOrder: string[];
  difficultyWeight: number;
  onMissAssign: string;
  nextDueAt: string;
}

export const createTask = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }
  const callerUid = request.auth.uid;

  const { homeId, task } = request.data as { homeId?: string; task?: TaskPayload };
  if (!homeId || !task || typeof task !== "object") {
    throw new HttpsError("invalid-argument", "homeId and task are required");
  }

  // --- Validación de campos (espejo de taskCreateValuesAllowed en rules) ---
  if (typeof task.title !== "string" || task.title.trim().length === 0) {
    throw new HttpsError("invalid-argument", "title-required");
  }
  if (!Array.isArray(task.assignmentOrder)) {
    throw new HttpsError("invalid-argument", "assignmentOrder-must-be-list");
  }
  if (typeof task.difficultyWeight !== "number") {
    throw new HttpsError("invalid-argument", "difficultyWeight-must-be-number");
  }
  if (typeof task.recurrenceType !== "string" || !VALID_RECURRENCE.has(task.recurrenceType)) {
    throw new HttpsError("invalid-argument", "recurrenceType-invalid");
  }
  const nextDueDate = new Date(task.nextDueAt);
  if (Number.isNaN(nextDueDate.getTime())) {
    throw new HttpsError("invalid-argument", "nextDueAt-invalid");
  }

  // --- Membership: admin u owner ACTIVO ---
  const homeRef = db.collection("homes").doc(homeId);
  const callerRef = homeRef.collection("members").doc(callerUid);
  const callerSnap = await callerRef.get();
  if (!callerSnap.exists) {
    throw new HttpsError("permission-denied", "Not a member of this home");
  }
  const caller = callerSnap.data()!;
  const callerRole = caller["role"] as string | undefined;
  const callerStatus = caller["status"] as string | undefined;
  if ((callerRole !== "admin" && callerRole !== "owner") || callerStatus !== "active") {
    throw new HttpsError("permission-denied", "Only active admins or the owner can create tasks");
  }

  const tasksRef = homeRef.collection("tasks");
  const newTaskRef = tasksRef.doc();
  const guardRef = homeRef.collection("system").doc("taskGuard");
  const isRecurring = task.recurrenceType !== "oneTime";

  await db.runTransaction(async (tx) => {
    // 1) Leer estado Premium del hogar.
    const homeSnap = await tx.get(homeRef);
    if (!homeSnap.exists) {
      throw new HttpsError("not-found", "Home not found");
    }
    const premium = isPremium(homeSnap.data()!["premiumStatus"] as string | undefined);

    // 2) smartDistribution es Premium (espejo de taskCreateSmartAllowed).
    if (task.assignmentMode === "smartDistribution" && !premium) {
      throw new HttpsError("permission-denied", "smart-distribution-requires-premium");
    }

    // 3) Enforcement del límite Free contando tareas REALES (no el contador
    //    denormalizado). Premium ignora el límite.
    if (!premium) {
      // Ancla de serialización: lee+escribe taskGuard para que dos altas
      // concurrentes no puedan ambas pasar sobre un conteo obsoleto.
      await tx.get(guardRef);
      const activeSnap = await tx.get(tasksRef.where("status", "==", "active"));
      const activeCount = activeSnap.size;
      const recurringCount = activeSnap.docs.filter(
        (d) => ((d.data()["recurrenceType"] as string | undefined) ?? "daily") !== "oneTime"
      ).length;

      if (activeCount >= FREE_LIMITS.maxActiveTasks) {
        throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.tasks);
      }
      if (isRecurring && recurringCount >= FREE_LIMITS.maxAutomaticRecurringTasks) {
        throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.recurring);
      }

      tx.set(
        guardRef,
        { seq: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    // 4) Escribir la tarea. Campos derivados/auditoría los fija el servidor
    //    (status, completedCount90d, createdByUid, timestamps).
    const order = task.assignmentOrder;
    tx.set(newTaskRef, {
      homeId,
      title: task.title.trim(),
      description:
        typeof task.description === "string" && task.description.trim().length > 0
          ? task.description.trim()
          : null,
      visualKind: task.visualKind,
      visualValue: task.visualValue,
      status: "active",
      recurrenceType: task.recurrenceType,
      recurrenceRule: task.recurrenceRule,
      assignmentMode: task.assignmentMode,
      assignmentOrder: order,
      currentAssigneeUid: order.length > 0 ? order[0] : null,
      nextDueAt: Timestamp.fromDate(nextDueDate),
      difficultyWeight: task.difficultyWeight,
      completedCount90d: 0,
      createdByUid: callerUid,
      onMissAssign: task.onMissAssign ?? "sameAssignee",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info(`createTask: task ${newTaskRef.id} created in home ${homeId} by ${callerUid}`);
  // El dashboard lo reconstruye el trigger `onTaskWriteUpdateDashboard`.
  return { taskId: newTaskRef.id };
});
