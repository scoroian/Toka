// functions/src/tasks/update_dashboard.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isPremium as isHomePremium } from "../shared/free_limits";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ---------------------------------------------------------------------------
// updateHomeDashboard
// Reconstruye el documento homes/{homeId}/views/dashboard.
// Llamada internamente desde funciones de completar tarea y pasar turno.
// ---------------------------------------------------------------------------
export async function updateHomeDashboard(homeId: string): Promise<void> {
  logger.info(`Rebuilding dashboard for home ${homeId}`);

  const homeRef = db.collection("homes").doc(homeId);
  const homeDoc = await homeRef.get();
  if (!homeDoc.exists) {
    logger.warn(`updateHomeDashboard: home ${homeId} not found`);
    return;
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
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

  const activeTasksPreview: Record<string, unknown>[] = [];
  let pendingTodayCount = 0; // tareas accionables hoy (vencidas + due today)
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
    if (nextDueAt < todayEnd) pendingTodayCount++;
    const isOverdue = nextDueAt < todayStart;

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
      status: "active",
    });
  }

  // --- 3. Leer completados de hoy desde taskEvents ---
  const eventsSnap = await homeRef.collection("taskEvents")
    .where("eventType", "==", "completed")
    .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(todayStart))
    .where("completedAt", "<", admin.firestore.Timestamp.fromDate(todayEnd))
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
  const adFlags = {
    showBanner: !isPremium,
    bannerUnit: "ca-app-pub-3940256099942544/6300978111", // test unit
  };
  const rescueFlags = {
    isInRescue: homeData["premiumStatus"] === "rescue",
    daysLeft: null as number | null,
  };

  // --- 6. Contadores ---
  const counters = {
    totalActiveTasks: tasksSnap.size,
    totalMembers: memberPreview.length,
    // tareas pendientes de hoy (no incluye las ya completadas)
    tasksDueToday: pendingTodayCount,
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

  // --- 7. Escribir dashboard ---
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  await dashboardRef.set({
    activeTasksPreview,
    doneTasksPreview,
    counters,
    planCounters,
    memberPreview,
    premiumFlags,
    adFlags,
    rescueFlags,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Update hasPendingToday: hay alguna tarea accionable hoy que no está completada
  const hasPendingToday = pendingTodayCount > 0;
  const membershipUpdates = memberPreview.map((m) =>
    db.collection("users").doc(m["uid"] as string)
      .collection("memberships").doc(homeId)
      .update({ hasPendingToday })
      .catch((err: unknown) =>
        logger.warn(`Could not update hasPendingToday for ${m["uid"] as string}: ${String(err)}`)
      )
  );
  await Promise.all(membershipUpdates);

  logger.info(`Dashboard updated for home ${homeId}`);
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
// Cron: reset diario a medianoche (00:00 UTC)
// ---------------------------------------------------------------------------
export const resetDashboardsDaily = onSchedule(
  { schedule: "0 0 * * *", timeZone: "UTC" },
  async () => {
    logger.info("Starting daily dashboard reset for all homes");

    const homesSnap = await db.collection("homes")
      .where("premiumStatus", "!=", "purged")
      .get();

    const updates = homesSnap.docs.map((doc) =>
      updateHomeDashboard(doc.id).catch((err) =>
        logger.error(`Failed to reset dashboard for ${doc.id}:`, err)
      )
    );

    await Promise.all(updates);
    logger.info(`Daily dashboard reset complete for ${homesSnap.size} homes`);
  }
);
