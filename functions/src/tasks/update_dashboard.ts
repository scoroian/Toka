// functions/src/tasks/update_dashboard.ts
import * as admin from "firebase-admin";
import { getFunctions } from "firebase-admin/functions";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isPremium as isHomePremium } from "../shared/free_limits";
import { buildBannerAdFlags } from "../shared/ad_constants";
import {
  classifyDue,
  summarizeDue,
  normalizeTimeZone,
  localDayBoundsUtc,
} from "./today_window";
import { dashboardRelevantFieldsChanged } from "./dashboard_dedup";
import {
  applyDashboardDelta,
  type DashboardChange,
  type DashboardData,
} from "./dashboard_delta";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ---------------------------------------------------------------------------
// updateHomeDashboard
// Reconstruye el documento homes/{homeId}/views/dashboard.
// Llamada internamente desde funciones de completar tarea y pasar turno.
// ---------------------------------------------------------------------------
/** Resultado del cómputo completo del dashboard (sin `rev`/`updatedAt`). */
interface BuiltDashboard {
  dashboardData: Record<string, unknown>;
  hasPendingToday: boolean;
  memberUids: string[];
}

/**
 * Lee el estado del hogar (miembros + tareas activas + eventos de hoy) y COMPUTA
 * el contenido del dashboard, SIN escribirlo. Es la parte cara (lecturas
 * O(miembros+tareas+eventos)); las escrituras las hacen los wrappers
 * transaccionales `updateHomeDashboard` (rebuild completo) o, en la ruta caliente,
 * `applyDashboardDeltaTx` (delta incremental).
 */
async function buildDashboardData(homeId: string): Promise<BuiltDashboard | null> {
  const homeRef = db.collection("homes").doc(homeId);
  const homeDoc = await homeRef.get();
  if (!homeDoc.exists) {
    logger.warn(`updateHomeDashboard: home ${homeId} not found`);
    return null;
  }
  const homeData = homeDoc.data()!;

  // --- 1. Leer miembros activos para resolver nombres al construir previews ---
  const membersSnap = await homeRef.collection("members").get();
  const memberMap = new Map<string, { nickname: string; photoUrl: string | null }>();

  // Para miembros sin nickname/photoUrl denormalizados, fallback a users/{uid}
  const uidsNeedingFallback: string[] = [];
  for (const mDoc of membersSnap.docs) {
    const m = mDoc.data();
    const nickname = (m["nickname"] as string | undefined) ?? "";
    const photoUrl = (m["photoUrl"] as string | undefined) ?? null;
    memberMap.set(mDoc.id, { nickname, photoUrl });
    if (!nickname) uidsNeedingFallback.push(mDoc.id);
  }

  if (uidsNeedingFallback.length > 0) {
    const userDocs = await Promise.all(
      uidsNeedingFallback.map((uid) => db.collection("users").doc(uid).get())
    );
    for (const userDoc of userDocs) {
      if (!userDoc.exists) continue;
      const u = userDoc.data()!;
      const existing = memberMap.get(userDoc.id)!;
      memberMap.set(userDoc.id, {
        nickname: existing.nickname || ((u["nickname"] as string | undefined) ?? ""),
        photoUrl: existing.photoUrl ?? ((u["photoUrl"] as string | undefined) ?? null),
      });
    }
  }

  // --- 2. Leer TODAS las tareas activas del hogar ---
  const tasksSnap = await homeRef.collection("tasks")
    .where("status", "==", "active")
    .get();

  const now = admin.firestore.Timestamp.now().toDate();
  // "Hoy" se define SIEMPRE en la zona horaria del hogar (no en la del proceso,
  // que es UTC, ni en la del dispositivo). Así el contador coincide con lo que
  // ve cualquier miembro. Los hogares antiguos sin `timezone` caen a Madrid.
  const homeTimeZone = normalizeTimeZone(
    homeData["timezone"] as string | undefined
  );

  // --- Contadores del día con la zona del hogar ---
  // tasksDueToday = SOLO las que vencen hoy (estricto). Las vencidas de días
  // anteriores se muestran arriba en la lista pero NO inflan el contador.
  // pendingTodayCount (vencidas + hoy) alimenta `hasPendingToday` del selector.
  const dueDates = tasksSnap.docs
    .map((d) =>
      (d.data()["nextDueAt"] as admin.firestore.Timestamp | undefined)?.toDate()
    )
    .filter((d): d is Date => !!d);
  const {
    bounds: dayBounds,
    dueTodayCount,
    pendingTodayCount,
  } = summarizeDue(dueDates, now, homeTimeZone);

  const activeTasksPreview: Record<string, unknown>[] = [];
  let automaticRecurringTasks = 0; // tareas activas con recurrencia automática (no oneTime)
  for (const doc of tasksSnap.docs) {
    const t = doc.data();
    const recurrenceType = (t["recurrenceType"] as string) ?? "daily";
    if (recurrenceType !== "oneTime") automaticRecurringTasks++;
    const nextDueAt = (t["nextDueAt"] as admin.firestore.Timestamp | undefined)?.toDate();
    if (!nextDueAt) continue;
    // Incluir TODAS las tareas activas (también las de próximas semanas/meses/años)
    // para que la pantalla Hoy muestre las próximas fechas de cada tarea.
    // El cliente Flutter decide si el botón "Hecho" está activo según recurrenceType.
    // La clasificación overdue/today/future es la MISMA que usan los contadores
    // (zona del hogar) para que el contador y las etiquetas de los tiles cuadren.
    const bucket = classifyDue(nextDueAt, dayBounds);
    const isOverdue = bucket === "overdue";
    const isDueToday = bucket === "today";

    const assigneeUid = (t["currentAssigneeUid"] as string | null) ?? null;
    const assigneeInfo = assigneeUid ? memberMap.get(assigneeUid) : undefined;

    activeTasksPreview.push({
      taskId: doc.id,
      title: t["title"] ?? "",
      visualKind: t["visualKind"] ?? "emoji",
      visualValue: t["visualValue"] ?? "",
      recurrenceType: t["recurrenceType"] ?? "daily",
      currentAssigneeUid: assigneeUid,
      currentAssigneeName: assigneeInfo?.nickname ?? null,
      currentAssigneePhoto: assigneeInfo?.photoUrl ?? null,
      nextDueAt: t["nextDueAt"],
      isOverdue,
      isDueToday,
      status: "active",
    });
  }

  // --- 3. Leer completados de hoy desde taskEvents ---
  const eventsSnap = await homeRef.collection("taskEvents")
    .where("eventType", "==", "completed")
    .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(dayBounds.start))
    .where("completedAt", "<", admin.firestore.Timestamp.fromDate(dayBounds.end))
    .get();

  const doneTasksPreview: Record<string, unknown>[] = [];
  for (const doc of eventsSnap.docs) {
    const ev = doc.data();
    const actorUid = (ev["actorUid"] as string) ?? "";
    const actorInfo = memberMap.get(actorUid);
    const visualSnapshot = (ev["taskVisualSnapshot"] as Record<string, string>) ?? {};
    // Obtener recurrenceType desde la tarea si está disponible
    const taskId = (ev["taskId"] as string) ?? doc.id;
    const matchingTask = tasksSnap.docs.find((d) => d.id === taskId);
    const recurrenceType = (matchingTask?.data()["recurrenceType"] as string) ?? "daily";
    doneTasksPreview.push({
      taskId,
      title: ev["taskTitleSnapshot"] ?? "",
      visualKind: visualSnapshot["kind"] ?? "emoji",
      visualValue: visualSnapshot["value"] ?? "",
      recurrenceType,
      completedByUid: actorUid,
      completedByName: actorInfo?.nickname ?? "",
      completedByPhoto: actorInfo?.photoUrl ?? null,
      completedAt: ev["completedAt"],
    });
  }

  // --- 4. Construir memberPreview desde el memberMap ya cargado ---
  const memberPreview: Record<string, unknown>[] = [];
  let totalAdmins = 0;
  for (const doc of membersSnap.docs) {
    const m = doc.data();
    if (m["status"] !== "active") continue;
    const memberTaskCount = activeTasksPreview.filter(
      (t) => t["currentAssigneeUid"] === doc.id
    ).length;
    const role = (m["role"] as string) ?? "member";
    // Para los límites Free, contamos como "admin" a owner + admin. El owner
    // siempre es admin-equivalente, así que maxAdminsTotal = 1 implica que
    // sólo el owner puede tener role ∈ {owner, admin}.
    if (role === "admin" || role === "owner") totalAdmins++;
    memberPreview.push({
      uid: doc.id,
      name: (m["nickname"] as string) ?? "",
      photoUrl: m["photoUrl"] ?? null,
      role,
      status: "active",
      tasksDueCount: memberTaskCount,
    });
  }

  // --- 5. Flags premium ---
  const premiumStatus = homeData["premiumStatus"] as string | undefined;
  const isPremium = isHomePremium(premiumStatus);
  const premiumFlags = {
    isPremium,
    showAds: !isPremium,
    canUseSmartDistribution: isPremium,
    canUseVacations: isPremium,
    canUseReviews: isPremium,
  };
  const adFlags = buildBannerAdFlags(!isPremium);
  // BUG-16: daysLeft se calcula con Math.ceil para no mostrar "0 días"
  // mientras aún quedan unas horas. Si faltan 2.9 días → 3, no 2.
  const premiumEndsAt = (homeData["premiumEndsAt"] as admin.firestore.Timestamp | undefined)?.toDate();
  const rescueDaysLeft =
    homeData["premiumStatus"] === "rescue" && premiumEndsAt
      ? Math.max(0, Math.ceil((premiumEndsAt.getTime() - Date.now()) / 86400000))
      : null;
  const rescueFlags = {
    isInRescue: homeData["premiumStatus"] === "rescue",
    daysLeft: rescueDaysLeft as number | null,
  };

  // --- 6. Contadores ---
  const counters = {
    totalActiveTasks: tasksSnap.size,
    totalMembers: memberPreview.length,
    // tareas que vencen HOY (estricto, zona del hogar; no incluye vencidas ni
    // las ya completadas)
    tasksDueToday: dueTodayCount,
    tasksDoneToday: doneTasksPreview.length,
  };

  // Contadores exigidos por la política Free (spec 2026-04-21). Se escriben
  // también en Premium para que la UI pueda mostrarlos como información.
  const planCounters = {
    activeMembers: memberPreview.length,
    activeTasks: tasksSnap.size,
    automaticRecurringTasks,
    totalAdmins,
  };

  // --- 7. Empaquetar contenido (la escritura la hace el wrapper) ---
  return {
    dashboardData: {
      activeTasksPreview,
      doneTasksPreview,
      counters,
      planCounters,
      memberPreview,
      premiumFlags,
      adFlags,
      rescueFlags,
    },
    // hasPendingToday: hay alguna tarea accionable hoy que no está completada.
    hasPendingToday: pendingTodayCount > 0,
    memberUids: memberPreview.map((m) => m["uid"] as string),
  };
}

// ---------------------------------------------------------------------------
// Escritura del dashboard — Hallazgo #16 (hot document)
//
// El doc `views/dashboard` es un punto caliente. Antes se hacía un `.set()`
// completo FUERA de transacción en cada acción, lo que permitía una
// lost-update race entre reconstrucciones concurrentes (la que lee antes pero
// escribe después pisa el estado más nuevo). Ahora todas las escrituras llevan
// un `rev` monotónico y van en transacción:
//  - El delta (`applyDashboardDeltaTx`) lee y escribe el doc en la MISMA
//    transacción → serializable: dos completaciones concurrentes no se pierden.
//  - El rebuild completo (`updateHomeDashboard`) hace sus lecturas pesadas fuera
//    de la transacción y, en la escritura, comprueba que `rev` no avanzó durante
//    su ventana de lectura; si avanzó (otro escritor entró), reintenta con datos
//    frescos (anti lost-update). El fan-out de `hasPendingToday` a las
//    memberships solo ocurre cuando el flag CAMBIA de valor (no fan-out ciego).
// ---------------------------------------------------------------------------

const MAX_REBUILD_ATTEMPTS = 4;

/**
 * Propaga `hasPendingToday` (flag home-level) a la membership de cada miembro.
 * Best-effort: un fallo por miembro se loguea y no aborta el resto.
 */
async function fanOutHasPendingToday(
  homeId: string,
  memberUids: string[],
  hasPendingToday: boolean
): Promise<void> {
  await Promise.all(
    memberUids.map((uid) =>
      db
        .collection("users").doc(uid)
        .collection("memberships").doc(homeId)
        .update({ hasPendingToday })
        .catch((err: unknown) =>
          logger.warn(`Could not update hasPendingToday for ${uid}: ${String(err)}`)
        )
    )
  );
}

/**
 * Reconstruye COMPLETO el documento del dashboard. Fuente de verdad e
 * idempotente: reconstruye desde cero, así que reintentos producen el mismo
 * resultado. Sirve de red de seguridad del delta (trigger + cron) y para las
 * acciones que no tienen ruta de delta (alta/edición/borrado, reasignación).
 */
export async function updateHomeDashboard(homeId: string): Promise<void> {
  logger.info(`Rebuilding dashboard for home ${homeId}`);
  const dashboardRef = db
    .collection("homes").doc(homeId)
    .collection("views").doc("dashboard");

  for (let attempt = 1; attempt <= MAX_REBUILD_ATTEMPTS; attempt++) {
    // `rev` ANTES de las lecturas pesadas: si cambia para cuando escribimos, otro
    // escritor entró durante nuestra ventana de lectura y nuestros datos pueden
    // ser viejos → reintentamos con lecturas frescas.
    const baselineSnap = await dashboardRef.get();
    const baselineRev = (baselineSnap.data()?.["rev"] as number | undefined) ?? 0;

    const built = await buildDashboardData(homeId);
    if (built === null) return; // hogar inexistente
    const { dashboardData, hasPendingToday, memberUids } = built;

    const isFinalAttempt = attempt === MAX_REBUILD_ATTEMPTS;
    const res = await db.runTransaction(async (tx) => {
      const cur = await tx.get(dashboardRef);
      const curRev = (cur.data()?.["rev"] as number | undefined) ?? 0;
      // En el último intento escribimos igualmente (datos casi frescos; el cron y
      // los siguientes triggers reconcilian) para no quedarnos sin actualizar.
      if (!isFinalAttempt && curRev !== baselineRev) {
        return { committed: false as const };
      }
      const prevHasPending = cur.data()?.["hasPendingToday"] as boolean | undefined;
      tx.set(dashboardRef, {
        ...dashboardData,
        hasPendingToday,
        rev: curRev + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { committed: true as const, prevHasPending };
    });

    if (!res.committed) {
      logger.info(
        `updateHomeDashboard: rev cambió durante la lectura de ${homeId}; reintento ${attempt}`
      );
      continue;
    }
    if (res.prevHasPending !== hasPendingToday) {
      await fanOutHasPendingToday(homeId, memberUids, hasPendingToday);
    }
    logger.info(`Dashboard updated for home ${homeId}`);
    return;
  }
}

/**
 * Aplica un DELTA incremental al dashboard por una acción de completar/pasar,
 * en una transacción de UN solo documento (lee + escribe `views/dashboard`),
 * sin releer todas las tareas/eventos. Devuelve `false` si el dashboard no
 * existe o hay deriva (la tarea no está en el preview): el llamante debe caer
 * entonces al rebuild completo.
 */
export async function applyDashboardDeltaTx(
  homeId: string,
  change: DashboardChange
): Promise<boolean> {
  const homeRef = db.collection("homes").doc(homeId);
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  const now = admin.firestore.Timestamp.now().toDate();

  const res = await db.runTransaction(async (tx) => {
    const [homeSnap, dashSnap] = await Promise.all([
      tx.get(homeRef),
      tx.get(dashboardRef),
    ]);
    if (!dashSnap.exists) return { applied: false as const };

    const tz = normalizeTimeZone(homeSnap.data()?.["timezone"] as string | undefined);
    const bounds = localDayBoundsUtc(now, tz);
    const cur = dashSnap.data() as Record<string, unknown>;
    const delta = applyDashboardDelta(cur as unknown as DashboardData, change, {
      startMs: bounds.start.getTime(),
      endMs: bounds.end.getTime(),
    });
    if (delta.needsFullRebuild || !delta.patch) return { applied: false as const };

    const curRev = (cur["rev"] as number | undefined) ?? 0;
    tx.set(
      dashboardRef,
      {
        ...delta.patch,
        hasPendingToday: delta.hasPendingToday,
        rev: curRev + 1,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return {
      applied: true as const,
      hasPendingToday: delta.hasPendingToday as boolean,
      prevHasPending: cur["hasPendingToday"] as boolean | undefined,
      memberUids: delta.patch.memberPreview.map((m) => m.uid),
    };
  });

  if (!res.applied) return false;
  if (res.prevHasPending !== res.hasPendingToday) {
    await fanOutHasPendingToday(homeId, res.memberUids, res.hasPendingToday);
  }
  return true;
}

// ---------------------------------------------------------------------------
// refreshDashboard — callable para reconstruir el dashboard desde el cliente
// (llamado tras crear/editar/congelar/eliminar tareas desde Flutter)
// Input:  { homeId: string }
// ---------------------------------------------------------------------------
export const refreshDashboard = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }
  const { homeId } = request.data as { homeId?: string };
  if (!homeId) throw new HttpsError("invalid-argument", "homeId is required");

  // Verificar que el usuario es miembro del hogar
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(request.auth.uid);
  const memberDoc = await memberRef.get();
  if (!memberDoc.exists) throw new HttpsError("permission-denied", "Not a member of this home");

  await updateHomeDashboard(homeId);
  return { ok: true };
});

// ---------------------------------------------------------------------------
// onTaskWriteUpdateDashboard — trigger Firestore (Hallazgo #07)
//
// Reconstruye el dashboard del hogar ante CUALQUIER alta/edición/borrado de una
// tarea, sin depender de que el cliente llame a `refreshDashboard` (cuya llamada
// podía fallar silenciosamente y dejar la pantalla "Hoy" desfasada). Es la
// garantía server-side equivalente a la que ya tienen completar/pasar turno.
//
// Coste acotado: cada escritura de tarea provoca como mucho UNA reconstrucción
// (las mismas lecturas O(miembros+tareas+eventos) que el cron diario, sin
// fan-out ni recursión). En ediciones que no tocan ningún campo que el dashboard
// muestre, se omite la reconstrucción (ver `dashboardRelevantFieldsChanged`).
// Idempotente: `updateHomeDashboard` reconstruye el documento desde cero, así
// que reintentos del trigger producen el mismo resultado.
//
// No hay bucle: `updateHomeDashboard` escribe en `views/dashboard` y en
// `users/{uid}/memberships`, nunca en `homes/{homeId}/tasks/{taskId}`.
// ---------------------------------------------------------------------------

export const onTaskWriteUpdateDashboard = onDocumentWritten(
  "homes/{homeId}/tasks/{taskId}",
  async (event) => {
    const homeId = event.params.homeId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // Evento sin payload (no debería ocurrir): nada que reconstruir.
    if (!before && !after) return;

    if (before && after) {
      // Hallazgo #16: completar/pasar turno ya actualizaron el dashboard con un
      // DELTA en su propia callable y marcaron la tarea con `dashboardDeltaToken`.
      // Si esta escritura llevaba un token NUEVO, el delta ya hizo el trabajo:
      // saltamos el rebuild redundante (reducir escrituras al doc caliente).
      const tokBefore = before["dashboardDeltaToken"];
      const tokAfter = after["dashboardDeltaToken"];
      if (tokAfter !== undefined && tokAfter !== tokBefore) {
        return;
      }
      // Edición normal: reconstruir sólo si cambió algo que el dashboard muestra.
      // (Alta — sólo `after` — y borrado físico — sólo `before` — siempre
      // reconstruyen. El borrado lógico es un update status→deleted, relevante.)
      if (!dashboardRelevantFieldsChanged(before, after)) {
        return;
      }
    }

    await updateHomeDashboard(homeId);
  }
);

// ---------------------------------------------------------------------------
// Cron: reset diario a medianoche (00:00 UTC) — fan-out por hogar
//
// Hallazgo #15 (coste lineal + job monolítico): antes este cron reconstruía
// TODOS los dashboards en UNA invocación (`Promise.all` sobre todos los hogares),
// lo que con N hogares dispara O(N·(miembros+tareas+eventos)) lecturas y
// O(N·miembros) escrituras concurrentes en un solo proceso → riesgo de exceder
// la ventana/memoria de la función, y un fallo quedaba sólo logueado.
//
// Ahora hacemos fan-out: el cron enumera los hogares vivos y encola UNA tarea
// de Cloud Tasks por hogar (`rebuildHomeDashboardTask`). Cada hogar se procesa
// en su PROPIA invocación → aislamiento (un fallo no tumba a los demás) y
// reintento automático con backoff (lo da Cloud Tasks), sin un solo proceso
// gigante.
// ---------------------------------------------------------------------------

/** Nombre del task queue function (debe coincidir con el export de abajo). */
const DASHBOARD_REBUILD_QUEUE = "rebuildHomeDashboardTask";

/** Encola en producción la reconstrucción de UN hogar vía Cloud Tasks. */
async function enqueueViaCloudTasks(homeId: string): Promise<void> {
  await getFunctions()
    .taskQueue(DASHBOARD_REBUILD_QUEUE)
    .enqueue({ homeId });
}

/**
 * Enumera los hogares vivos (no `purged`) y encola UNA reconstrucción por hogar
 * mediante el callback `enqueue` (en prod, Cloud Tasks). Resiliente: si encolar
 * un hogar falla, se registra y se continúa con el resto (un hogar no aborta el
 * fan-out completo). `enqueue` es inyectable para tests. Devuelve cuántos se
 * encolaron y cuántos fallaron.
 */
export async function enqueueDashboardRebuilds(
  enqueue: (homeId: string) => Promise<void>
): Promise<{ enqueued: number; failed: number }> {
  // `.select()` (sin campos) trae sólo las referencias: no necesitamos los datos
  // del hogar, sólo su id para encolar.
  const homesSnap = await db.collection("homes")
    .where("premiumStatus", "!=", "purged")
    .select()
    .get();

  let enqueued = 0;
  let failed = 0;
  for (const doc of homesSnap.docs) {
    try {
      await enqueue(doc.id);
      enqueued++;
    } catch (err) {
      failed++;
      logger.error(`Failed to enqueue dashboard rebuild for ${doc.id}:`, err);
    }
  }
  logger.info(
    `enqueueDashboardRebuilds: ${enqueued} enqueued, ${failed} failed of ${homesSnap.size} homes`
  );
  return { enqueued, failed };
}

/**
 * Reconstruye el dashboard de UN hogar. Es la unidad que ejecuta cada tarea de
 * Cloud Tasks: si lanza, Cloud Tasks reintenta SOLO ese hogar (aislamiento +
 * reintento), sin afectar a los demás. `updater` es inyectable para tests.
 */
export async function rebuildDashboardForHome(
  homeId: string,
  updater: (homeId: string) => Promise<void> = updateHomeDashboard
): Promise<void> {
  await updater(homeId);
}

export const resetDashboardsDaily = onSchedule(
  { schedule: "0 0 * * *", timeZone: "UTC" },
  async () => {
    logger.info("Starting daily dashboard reset fan-out");
    const { enqueued, failed } = await enqueueDashboardRebuilds(enqueueViaCloudTasks);
    logger.info(`Daily dashboard reset fan-out done: ${enqueued} enqueued, ${failed} failed`);
  }
);

/**
 * Cola de Cloud Tasks que reconstruye el dashboard de un hogar. Una invocación
 * por hogar → aislamiento. `retryConfig` da reintentos con backoff si un hogar
 * falla; `maxConcurrentDispatches` acota la concurrencia para no saturar
 * Firestore cuando hay muchos hogares.
 */
export const rebuildHomeDashboardTask = onTaskDispatched(
  {
    retryConfig: { maxAttempts: 5, minBackoffSeconds: 30, maxBackoffSeconds: 300 },
    rateLimits: { maxConcurrentDispatches: 10 },
    // Una cola de Cloud Tasks NO debe ser pública: la invoca Cloud Tasks con una
    // service account. `invoker: "private"` sobreescribe el `invoker: "public"`
    // global (setGlobalOptions) que, al intentar enlazar `allUsers`, choca con la
    // org policy de toka-dd241 (restrict allUsers) y rompía el deploy.
    invoker: "private",
  },
  async (req) => {
    const homeId = (req.data as { homeId?: string } | undefined)?.homeId;
    if (!homeId) {
      logger.warn("rebuildHomeDashboardTask: payload sin homeId, se ignora");
      return;
    }
    // Si updateHomeDashboard lanza, dejamos propagar para que Cloud Tasks
    // reintente SOLO este hogar.
    await rebuildDashboardForHome(homeId);
  }
);
