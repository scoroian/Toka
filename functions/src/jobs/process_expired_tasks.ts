// functions/src/jobs/process_expired_tasks.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { computeNextDueAt } from "../tasks/recurrence_calculator";
import { getNextEligibleMember } from "../tasks/pass_turn_helpers";
import { isMemberCurrentlyAbsent } from "../shared/vacation";

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

// Hallazgo #16: el cron tenía un `.limit(100)` GLOBAL (todo el sistema). Con más
// de 100 tareas vencidas en un día, las sobrantes nunca se procesaban → deuda
// acumulada perpetua que CRECE con el número de hogares. Ahora:
//  - PAGINA con `startAfter` hasta vaciar el conjunto de vencidas (fase de
//    recogida, sin mutar → paginación estable), con un cap de seguridad ALTO y
//    LOGUEADO (no silencioso) para acotar la ventana del cron en casos extremos;
//  - CACHEA los miembros por hogar (la clasificación frozen/absent/left se lee
//    UNA vez por hogar, no por cada tarea), eliminando el read de la colección
//    `members` completa que hacía cada transacción.
const PAGE_SIZE = 300;
const MAX_TASKS_PER_RUN = 5000;

/** Excluidos de la rotación de un hogar: congelados, ausentes y ex-miembros. */
async function loadHomeFrozenUids(
  db: admin.firestore.Firestore,
  homeId: string,
  cache: Map<string, string[]>
): Promise<string[]> {
  const cached = cache.get(homeId);
  if (cached) return cached;
  const membersSnap = await db.collection("homes").doc(homeId).collection("members").get();
  const frozenUids: string[] = [];
  for (const mDoc of membersSnap.docs) {
    const md = mDoc.data();
    if (md["status"] === "left" || md["status"] === "frozen" || isMemberCurrentlyAbsent(md)) {
      frozenUids.push(mDoc.id);
    }
  }
  cache.set(homeId, frozenUids);
  return frozenUids;
}

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
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

  logger.info(`processExpiredTasks: cutoff = ${cutoff.toISOString()}`);

  // --- Fase 1: recoger TODAS las refs vencidas (paginado, sin mutar) ---
  const expiredDocs: admin.firestore.QueryDocumentSnapshot[] = [];
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  let reachedCap = false;
  for (;;) {
    let q = db
      .collectionGroup("tasks")
      .where("status", "==", "active")
      .where("nextDueAt", "<", cutoffTs)
      .orderBy("nextDueAt")
      .limit(PAGE_SIZE);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    for (const d of snap.docs) {
      expiredDocs.push(d);
      if (expiredDocs.length >= MAX_TASKS_PER_RUN) {
        reachedCap = true;
        break;
      }
    }
    if (reachedCap || snap.docs.length < PAGE_SIZE) break;
    lastDoc = snap.docs[snap.docs.length - 1];
  }

  if (expiredDocs.length === 0) {
    logger.info("processExpiredTasks: no expired tasks found");
    return;
  }
  if (reachedCap) {
    logger.warn(
      `processExpiredTasks: alcanzado el cap de ${MAX_TASKS_PER_RUN} tareas/ejecución; ` +
        "el resto se procesará en la próxima ejecución (NO es silencioso)"
    );
  }
  logger.info(`processExpiredTasks: processing ${expiredDocs.length} tasks`);

  // --- Fase 2: procesar cada tarea una vez (cache de miembros por hogar) ---
  const frozenCache = new Map<string, string[]>();
  const affectedHomeIds = new Set<string>();

  // Secuencial a propósito: varias tareas del mismo actor incrementan su
  // missedCount; en secuencia la complianceRate final queda consistente con el
  // missedCount (cada tx lee el estado fresco del actor).
  for (const taskDoc of expiredDocs) {
    // homeId se obtiene del path: homes/{homeId}/tasks/{taskId}
    const pathParts = taskDoc.ref.path.split("/");
    const homeId = pathParts[1];
    const taskId = taskDoc.id;

    try {
      // Cache por hogar: la clasificación frozen/absent/left se lee UNA vez por
      // hogar, no por cada tarea (antes cada tx leía toda la colección members).
      const frozenUids = await loadHomeFrozenUids(db, homeId, frozenCache);

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

        // Hallazgo #10: siguiente ocurrencia tz-aware desde la RecurrenceRule
        // (hora de pared estable en DST), no suma de intervalo en UTC.
        const nextDueAt = computeNextDueAt(task, taskNextDue.toDate());

        // Solo se lee el doc del ACTOR dentro de la tx (para stats consistentes),
        // no la colección entera; la exclusión de rotación viene del cache.
        const memberRef = db.collection("homes").doc(homeId).collection("members").doc(actorUid);
        const memberSnap = await tx.get(memberRef);
        const member = memberSnap.data() ?? {};

        // Hallazgo #09: si el responsable está de VACACIONES no se le penaliza.
        // No "incumplió": no pudo actuar. La tarea simplemente RUEDA hacia un
        // miembro presente (ignorando onMissAssign, igual que pasar turno) y
        // NO se emite evento `missed` ni se tocan sus estadísticas. Permanece
        // en assignmentOrder, así que vuelve a la rotación al regresar.
        if (isMemberCurrentlyAbsent(member)) {
          const toUid = getNextEligibleMember(assignmentOrder, actorUid, frozenUids);
          tx.update(taskRef, {
            currentAssigneeUid: toUid,
            nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
            updatedAt: FieldValue.serverTimestamp(),
          });
          return; // sin penalización ni evento
        }

        const toUid = computeNextAssignee(onMissAssign, actorUid, assignmentOrder, frozenUids);

        // Stats del miembro que incumplió
        const completed: number = (member["tasksCompleted"] as number) ?? (member["completedCount"] as number) ?? 0;
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
    } catch (err) {
      logger.error(`processExpiredTasks: error processing task ${taskId}`, err);
    }
  }

  logger.info(
    `processExpiredTasks: done. Processed ${expiredDocs.length} tasks; affected homes: ${affectedHomeIds.size}`
  );
});
