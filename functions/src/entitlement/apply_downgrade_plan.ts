// functions/src/entitlement/apply_downgrade_plan.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { autoSelectForDowngrade } from "./downgrade_helpers";
import { DEFAULT_BANNER_UNIT_ID } from "../shared/ad_constants";

/**
 * Cron cada 30 minutos. Aplica downgrade a hogares cuyo premiumEndsAt <= now
 * y que estén en estado rescue o cancelled_pending_end.
 */
export const applyDowngradeJob = onSchedule("*/30 * * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const now = admin.firestore.Timestamp.now();

  const snapshot = await db
    .collection("homes")
    .where("premiumStatus", "in", ["rescue", "cancelled_pending_end"])
    .where("premiumEndsAt", "<=", now)
    .get();

  logger.info(`applyDowngradeJob: ${snapshot.size} homes to downgrade`);

  for (const homeDoc of snapshot.docs) {
    const homeId = homeDoc.id;
    const homeData = homeDoc.data();
    const ownerId = homeData["ownerUid"] as string;

    try {
      const manualPlanRef = db
        .collection("homes")
        .doc(homeId)
        .collection("downgrade")
        .doc("current");
      const manualPlanSnap = await manualPlanRef.get();

      let selectedMemberIds: string[];
      let selectedTaskIds: string[];
      const selectionMode: "manual" | "auto" = manualPlanSnap.exists ? "manual" : "auto";

      if (manualPlanSnap.exists) {
        const plan = manualPlanSnap.data() as Record<string, unknown>;
        selectedMemberIds = (plan["selectedMemberIds"] as string[]) ?? [ownerId];
        selectedTaskIds = (plan["selectedTaskIds"] as string[]) ?? [];
      } else {
        const membersSnap = await db
          .collection("homes")
          .doc(homeId)
          .collection("members")
          .where("status", "==", "active")
          .get();

        const tasksSnap = await db
          .collection("homes")
          .doc(homeId)
          .collection("tasks")
          .where("status", "==", "active")
          .get();

        const members = membersSnap.docs.map((d) => {
          const data = d.data();
          return {
            uid: d.id,
            status: data["status"] as string,
            completions60d: (data["completions60d"] as number) ?? 0,
            lastCompletedAt: (data["lastCompletedAt"] as admin.firestore.Timestamp | null) ?? null,
            joinedAt: data["joinedAt"] as admin.firestore.Timestamp,
          };
        });

        const tasks = tasksSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            status: data["status"] as string,
            completedCount90d: (data["completedCount90d"] as number) ?? 0,
            nextDueAt: data["nextDueAt"] as admin.firestore.Timestamp,
          };
        });

        const selection = autoSelectForDowngrade(members, tasks, ownerId);
        selectedMemberIds = selection.selectedMemberIds;
        selectedTaskIds = selection.selectedTaskIds;
      }

      // Congelar miembros excedentes
      const allMembersSnap = await db
        .collection("homes")
        .doc(homeId)
        .collection("members")
        .get();

      const batch = db.batch();

      for (const memberDoc of allMembersSnap.docs) {
        const memberData = memberDoc.data();
        if (
          !selectedMemberIds.includes(memberDoc.id) &&
          memberData["status"] === "active"
        ) {
          batch.update(memberDoc.ref, {
            status: "frozen",
            frozenAt: FieldValue.serverTimestamp(),
          });
        }
      }

      // Congelar tareas excedentes
      const allTasksSnap = await db
        .collection("homes")
        .doc(homeId)
        .collection("tasks")
        .where("status", "==", "active")
        .get();

      for (const taskDoc of allTasksSnap.docs) {
        if (!selectedTaskIds.includes(taskDoc.id)) {
          batch.update(taskDoc.ref, {
            status: "frozen",
            frozenAt: FieldValue.serverTimestamp(),
          });
        }
      }

      // Actualizar estado del hogar
      const restoreUntil = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      batch.update(homeDoc.ref, {
        premiumStatus: "restorable",
        restoreUntil: admin.firestore.Timestamp.fromDate(restoreUntil),
        "limits.maxMembers": 3,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Guardar selección aplicada
      batch.set(
        manualPlanRef,
        {
          selectedMemberIds,
          selectedTaskIds,
          selectionMode,
          appliedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Actualizar dashboard
      const dashRef = db
        .collection("homes")
        .doc(homeId)
        .collection("views")
        .doc("dashboard");

      batch.set(
        dashRef,
        {
          premiumFlags: {
            isPremium: false,
            showAds: true,
            canUseSmartDistribution: false,
            canUseVacations: false,
            canUseReviews: false,
          },
          adFlags: {
            showBanner: true,
            bannerUnit: DEFAULT_BANNER_UNIT_ID,
          },
          rescueFlags: { isInRescue: false, daysLeft: null },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await batch.commit();
      logger.info(`applyDowngradeJob: home ${homeId} downgraded (${selectionMode})`);
    } catch (err) {
      logger.error(`applyDowngradeJob: error processing home ${homeId}`, err);
    }
  }
});
