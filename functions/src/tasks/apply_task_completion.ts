// functions/src/tasks/apply_task_completion.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard, applyDashboardDeltaTx } from "./update_dashboard";
import type { DashboardChange } from "./dashboard_delta";
import {
  MemberLoadData,
  CompletedLoadEvent,
  countCompletionsInWindow,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  isTerminalRecurrence,
} from "./task_assignment_helpers";
import { computeNextDueAt } from "./recurrence_calculator";
import { isMemberCurrentlyAbsent } from "../shared/vacation";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Hallazgo #13: ventana real de carga del reparto inteligente. Antes se usaba
// `members/{uid}.completions60d`, un contador que SOLO se incrementaba y NUNCA
// decaía → un miembro muy cumplidor en el pasado quedaba excluido del reparto
// para siempre. Ahora la carga se cuenta desde los eventos `taskEvents`
// 'completed' de los últimos LOAD_WINDOW_DAYS días (fuente fechada y
// auto-limpiante; ningún job de barrido necesario).
const LOAD_WINDOW_DAYS = 60;

/**
 * Cuenta, por miembro, las completaciones de los últimos `windowDays` días
 * leyendo los eventos `taskEvents` de tipo 'completed'. Usa el índice compuesto
 * (eventType, completedAt) ya declarado en `firestore.indexes.json`. Se ejecuta
 * FUERA de la transacción de completación: el reparto inteligente es una
 * heurística y no necesita consistencia transaccional; así evitamos añadir un
 * range-read al conjunto de lectura de la transacción (menos contención).
 */
async function loadRecentCompletionCounts(
  homeId: string,
  windowDays: number
): Promise<Map<string, number>> {
  const cutoff = admin.firestore.Timestamp.fromMillis(
    Date.now() - windowDays * 24 * 60 * 60 * 1000
  );
  const snap = await db
    .collection("homes").doc(homeId).collection("taskEvents")
    .where("eventType", "==", "completed")
    .where("completedAt", ">=", cutoff)
    .get();
  const events: CompletedLoadEvent[] = snap.docs.map((d) => {
    const e = d.data();
    const completedAt = e["completedAt"] as admin.firestore.Timestamp | undefined;
    return {
      // `performerUid` es el canónico; `actorUid` como fallback para eventos
      // antiguos. En las completaciones ambos son el mismo uid.
      performerUid: (e["performerUid"] as string) ?? (e["actorUid"] as string) ?? "",
      completedAtMs: completedAt ? completedAt.toMillis() : 0,
    };
  });
  return countCompletionsInWindow(events, Date.now(), windowDays);
}

export const applyTaskCompletion = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, completionId } = request.data as {
    homeId: string;
    taskId: string;
    completionId?: string;
  };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }
  // Hallazgo #02: `completionId` es la clave de idempotencia generada por el
  // cliente (uuid). Se usa como id determinista del taskEvent, así que debe ser
  // un id de documento válido y acotado. Si es inválido, lo rechazamos en vez de
  // caer silenciosamente a un id automático (lo que perdería la idempotencia).
  if (
    completionId !== undefined &&
    (typeof completionId !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(completionId))
  ) {
    throw new HttpsError(
      "invalid-argument",
      "completionId must be a token of [A-Za-z0-9_-]{1,128}"
    );
  }

  // Pre-lectura (fuera de la transacción) del modo de distribución: solo el
  // reparto inteligente necesita la carga de 60 días, así que evitamos la query
  // extra de eventos para las tareas en round-robin. Si la tarea no existe, la
  // transacción de abajo lanzará not-found igualmente.
  const preTaskSnap = await db
    .collection("homes").doc(homeId).collection("tasks").doc(taskId).get();
  const preMode: string =
    (preTaskSnap.data()?.["distributionMode"] as string) ??
    (preTaskSnap.data()?.["assignmentMode"] as string) ??
    "round_robin";
  const isSmart = preMode === "smart" || preMode === "smartDistribution";
  const recentCompletionCounts = isSmart
    ? await loadRecentCompletionCounts(homeId, LOAD_WINDOW_DAYS)
    : new Map<string, number>();

  const result = await db.runTransaction(async (tx) => {
    // Id del evento: determinista (= completionId) cuando el cliente lo provee,
    // para que un reintento de una escritura ya aplicada sea un no-op.
    const eventRef = completionId
      ? db.collection("homes").doc(homeId).collection("taskEvents").doc(completionId)
      : db.collection("homes").doc(homeId).collection("taskEvents").doc();

    // Idempotencia (Hallazgo #02): si este completionId ya tiene evento, la
    // completación ya se aplicó (probablemente se perdió la respuesta). No
    // re-aplicamos nada — ni evento, ni stats, ni dashboard.
    if (completionId) {
      const existing = await tx.get(eventRef);
      if (existing.exists) {
        return {
          alreadyApplied: true,
          eventId: eventRef.id,
          nextAssigneeUid:
            (existing.data()?.["nextAssigneeUid"] as string | null) ?? null,
          isOneTime: false,
          nextDueAtMillis: 0,
        };
      }
    }

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
      // Excluir del siguiente reparto a congelados, ausentes (vacaciones) y
      // ex-miembros ('left'). Incluir 'left' (Hallazgo #08) evita reasignar la
      // tarea a un fantasma que siga en assignmentOrder.
      if (
        mData["status"] === "left" ||
        mData["status"] === "frozen" ||
        isMemberCurrentlyAbsent(mData)
      ) {
        excludedUids.push(mDoc.id);
      }
      const lastCompletedAt: admin.firestore.Timestamp | undefined = mData["lastCompletedAt"];
      const daysSince = lastCompletedAt
        ? Math.floor((Date.now() - lastCompletedAt.toMillis()) / (1000 * 60 * 60 * 24))
        : 0;
      loadDataMap.set(mDoc.id, {
        // Carga REAL de los últimos 60 días (Hallazgo #13), no el acumulado de
        // por vida `completions60d`. Si no hay datos (o la tarea no es smart),
        // el conteo es 0.
        completionsRecent: recentCompletionCounts.get(mDoc.id) ?? 0,
        difficultyWeight: 1.0,
        daysSinceLastExecution: daysSince,
      });
    }

    // Autorización: el caller debe ser miembro ACTIVO del hogar. No basta con
    // ser el currentAssigneeUid: un ex-miembro (status 'left') o congelado no
    // debe poder mutar contadores/streak/dashboard del hogar.
    const callerMember = membersSnap.docs.find((d) => d.id === uid)?.data();
    if (!callerMember || callerMember["status"] !== "active") {
      throw new HttpsError("permission-denied", "Not an active member of this home");
    }

    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const frozenUids: string[] = task["frozenUids"] ?? [];
    const allExcluded = [...new Set([...frozenUids, ...excludedUids])];
    const distributionMode: string = task["distributionMode"] ?? task["assignmentMode"] ?? "round_robin";

    let nextAssigneeUid: string;
    if (distributionMode === "smart" || distributionMode === "smartDistribution") {
      nextAssigneeUid = getNextAssigneeSmart(assignmentOrder, uid, allExcluded, loadDataMap);
    } else {
      nextAssigneeUid = getNextAssigneeRoundRobin(assignmentOrder, uid, allExcluded) ?? uid;
    }

    const currentDue = (task["nextDueAt"] as admin.firestore.Timestamp | undefined)
      ?.toDate() ?? admin.firestore.Timestamp.now().toDate();
    const recurrenceType: string = task["recurrenceType"] ?? "daily";
    const isOneTime = isTerminalRecurrence(recurrenceType);
    // Hallazgo #10: la siguiente ocurrencia se deriva de la RecurrenceRule en la
    // zona del hogar (tz-aware), manteniendo la hora de pared estable a través
    // de DST. Antes se sumaba el intervalo en UTC ignorando la regla.
    const nextDueAt = computeNextDueAt(task, currentDue);

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
      // Persistido para que un replay idempotente pueda devolverlo sin recalcular.
      nextAssigneeUid: isOneTime ? null : nextAssigneeUid,
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
      // Hallazgo #16: marca que esta escritura ya tiene su delta aplicado en la
      // callable, para que el trigger onWrite no haga un rebuild redundante.
      dashboardDeltaToken: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (isOneTime) {
      taskUpdate["status"] = "completedOneTime";
    }
    tx.update(taskRef, taskUpdate);

    // Usamos el snapshot ya leído de membersSnap para evitar read-after-write en la transacción.
    // Campo canónico: tasksCompleted (lo lee el cliente). Se conserva fallback
    // a completedCount para migrar suavemente datos escritos por la versión
    // anterior sin perder el conteo.
    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberDocInSnap = membersSnap.docs.find((d) => d.id === uid);
    const member = memberDocInSnap?.data() ?? {};
    const legacyCompleted = (member["completedCount"] as number | undefined) ?? 0;
    const completedBefore = (member["tasksCompleted"] as number | undefined) ?? legacyCompleted;
    const newCompleted = completedBefore + 1;
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
      tasksCompleted: newCompleted,
      completedCount: FieldValue.delete(),
      completions60d: FieldValue.increment(1),
      complianceRate: newCompliance,
      currentStreak: newStreak,
      lastCompletedAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return {
      alreadyApplied: false,
      eventId: eventRef.id,
      nextAssigneeUid,
      isOneTime,
      nextDueAtMillis: nextDueAt.getTime(),
    };
  });

  // Replay idempotente: la completación ya estaba aplicada → no tocamos el
  // dashboard (evitaría doble conteo) y devolvemos éxito.
  if (result.alreadyApplied) {
    return {
      eventId: result.eventId,
      nextAssigneeUid: result.nextAssigneeUid,
      deduped: true,
    };
  }

  // Actualizar el dashboard ANTES de responder al cliente. En Cloud Functions
  // gen2 (Cloud Run) el CPU se estrangula en cuanto se envía la respuesta, por lo
  // que un trabajo fire-and-forget quedaba en segundo plano y tardaba ~10s en
  // reflejarse en la pantalla Hoy. Hacerlo dentro del ciclo de la petición
  // elimina ese desfase.
  //
  // Hallazgo #16: en vez de reconstruir TODO el dashboard, aplicamos un DELTA
  // incremental (transacción de un solo doc → sin lost-update bajo concurrencia,
  // y O(preview) en memoria en vez de releer todas las tareas/eventos). Si el
  // dashboard no existe o hay deriva, caemos al rebuild completo. Un fallo no
  // revierte la completación (ya confirmada); el cron/trigger lo reconcilian.
  try {
    const change: DashboardChange = {
      kind: "completed",
      taskId,
      performedByUid: uid,
      isOneTime: result.isOneTime,
      newAssigneeUid: result.isOneTime ? null : result.nextAssigneeUid,
      newNextDueAt: admin.firestore.Timestamp.fromMillis(result.nextDueAtMillis),
      newNextDueAtMillis: result.isOneTime ? null : result.nextDueAtMillis,
      completedAt: admin.firestore.Timestamp.now(),
    };
    const applied = await applyDashboardDeltaTx(homeId, change);
    if (!applied) await updateHomeDashboard(homeId);
  } catch (err) {
    logger.error("Failed to apply dashboard delta after completion; rebuilding", err);
    try {
      await updateHomeDashboard(homeId);
    } catch (err2) {
      logger.error("Fallback dashboard rebuild after completion also failed", err2);
    }
  }

  return { eventId: result.eventId, nextAssigneeUid: result.nextAssigneeUid };
});
