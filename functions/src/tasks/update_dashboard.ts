// functions/src/tasks/update_dashboard.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

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

  // --- 1. Leer tareas activas del hogar ---
  const tasksSnap = await homeRef.collection("tasks")
    .where("status", "==", "active")
    .get();

  // --- 2. Determinar qué tareas son "de hoy" ---
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

  const activeTasksPreview: Record<string, unknown>[] = [];
  for (const doc of tasksSnap.docs) {
    const t = doc.data();
    const nextDueAt = (t["nextDueAt"] as admin.firestore.Timestamp | undefined)?.toDate();
    if (!nextDueAt) continue;
    const isOverdue = nextDueAt < todayStart;
    const isDueToday = nextDueAt >= todayStart && nextDueAt < todayEnd;
    if (!isDueToday && !isOverdue) continue;

    activeTasksPreview.push({
      taskId: doc.id,
      title: t["title"] ?? "",
      visualKind: t["visualKind"] ?? "emoji",
      visualValue: t["visualValue"] ?? "",
      recurrenceType: t["recurrenceType"] ?? "daily",
      currentAssigneeUid: t["currentAssigneeUid"] ?? null,
      currentAssigneeName: t["currentAssigneeName"] ?? null,
      currentAssigneePhoto: t["currentAssigneePhoto"] ?? null,
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
    const memberDoc = await homeRef.collection("members").doc(actorUid).get();
    const m = memberDoc.data() ?? {};
    const visualSnapshot = (ev["taskVisualSnapshot"] as Record<string, string>) ?? {};
    doneTasksPreview.push({
      taskId: ev["taskId"] ?? doc.id,
      title: ev["taskTitleSnapshot"] ?? "",
      visualKind: visualSnapshot["kind"] ?? "emoji",
      visualValue: visualSnapshot["value"] ?? "",
      recurrenceType: "daily",
      completedByUid: actorUid,
      completedByName: (m["name"] as string) ?? "",
      completedByPhoto: m["photoUrl"] ?? null,
      completedAt: ev["completedAt"],
    });
  }

  // --- 4. Leer miembros activos ---
  const membersSnap = await db.collectionGroup("memberships")
    .where("status", "==", "active")
    .get();

  const memberPreview: Record<string, unknown>[] = [];
  for (const doc of membersSnap.docs) {
    if (doc.ref.parent.parent?.id !== homeId) continue;
    const m = doc.data();
    const memberTaskCount = activeTasksPreview.filter(
      (t) => t["currentAssigneeUid"] === doc.id
    ).length;
    memberPreview.push({
      uid: doc.id,
      name: m["name"] ?? "",
      photoUrl: m["photoUrl"] ?? null,
      role: m["role"] ?? "member",
      status: "active",
      tasksDueCount: memberTaskCount,
    });
  }

  // --- 5. Flags premium ---
  const isPremium = homeData["premiumStatus"] !== "free" &&
    homeData["premiumStatus"] !== "expiredFree";
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
    tasksDueToday: activeTasksPreview.length,
    tasksDoneToday: doneTasksPreview.length,
  };

  // --- 7. Escribir dashboard ---
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  await dashboardRef.set({
    activeTasksPreview,
    doneTasksPreview,
    counters,
    memberPreview,
    premiumFlags,
    adFlags,
    rescueFlags,
    updatedAt: FieldValue.serverTimestamp(),
  });

  logger.info(`Dashboard updated for home ${homeId}`);
}

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
