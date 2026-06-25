// functions/src/entitlement/apply_downgrade_plan.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  autoSelectForDowngrade,
  DOWNGRADE_ELIGIBLE_STATUSES,
} from "./downgrade_helpers";
import { buildBannerAdFlags } from "../shared/ad_constants";
import { resolveEntitlement } from "../shared/tier_catalog";
import { isHomeTiersEnabled } from "../shared/feature_flags";
import { commitInChunks } from "../shared/batch_utils";

/**
 * Cron cada 30 minutos. Aplica downgrade a hogares cuyo premiumEndsAt <= now y
 * que estén en un estado elegible (ver DOWNGRADE_ELIGIBLE_STATUSES): rescue,
 * cancelled_pending_end/cancelledPendingEnd y `active` vencido sin renovación.
 */
export const applyDowngradeJob = onSchedule("*/30 * * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const now = admin.firestore.Timestamp.now();

  const snapshot = await db
    .collection("homes")
    // Incluye el valor canónico camelCase persistido por syncEntitlement
    // (`cancelledPendingEnd`), la variante legacy snake_case, y `active`: un
    // hogar cuyo periodo venció sin renovación se quedaría en Premium efectivo
    // perpetuo si no se captura aquí (Hallazgo #06).
    .where("premiumStatus", "in", [...DOWNGRADE_ELIGIBLE_STATUSES])
    .where("premiumEndsAt", "<=", now)
    .get();

  // El downgrade por expiración siempre va a Free (tope 3). El tier efectivo del
  // dashboard es 'free' (flag ON) o null (flag OFF, modo binario). NO se toca
  // `premiumTier` del hogar: se conserva sticky para poder restaurar el tope.
  const tiersEnabled = await isHomeTiersEnabled();
  const downgraded = resolveEntitlement({ premiumStatus: "restorable", tiersEnabled });

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

      // Recolectar los refs a congelar (miembros + tareas excedentes). Hallazgo
      // #16: un hogar grande (sin tope de tareas en Premium, y hasta 25 miembros
      // con packs) puede superar el límite DURO de 500 ops/batch — que el
      // emulador NO aplica → falso verde. Troceamos en lotes ≤MAX_BATCH_OPS y
      // dejamos el flip del hogar + dashboard + plan para el FINAL: si algo falla
      // a mitad, el hogar sigue en estado elegible y el cron reintenta
      // (idempotente: re-congelar lo ya congelado es un no-op).
      const allMembersSnap = await db
        .collection("homes")
        .doc(homeId)
        .collection("members")
        .get();

      const allTasksSnap = await db
        .collection("homes")
        .doc(homeId)
        .collection("tasks")
        .where("status", "==", "active")
        .get();

      const freezeRefs: admin.firestore.DocumentReference[] = [
        ...allMembersSnap.docs
          .filter((d) => !selectedMemberIds.includes(d.id) && d.data()["status"] === "active")
          .map((d) => d.ref),
        ...allTasksSnap.docs
          .filter((d) => !selectedTaskIds.includes(d.id))
          .map((d) => d.ref),
      ];

      await commitInChunks(
        freezeRefs,
        () => db.batch(),
        (batch, ref) =>
          batch.update(ref, {
            status: "frozen",
            frozenAt: FieldValue.serverTimestamp(),
          }),
      );

      // Flip del hogar + plan + dashboard (nº fijo de ops, nunca supera el límite).
      const restoreUntil = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      const dashRef = db
        .collection("homes")
        .doc(homeId)
        .collection("views")
        .doc("dashboard");
      const finalBatch = db.batch();

      finalBatch.update(homeDoc.ref, {
        premiumStatus: "restorable",
        restoreUntil: admin.firestore.Timestamp.fromDate(restoreUntil),
        "limits.maxMembers": downgraded.maxMembers,
        updatedAt: FieldValue.serverTimestamp(),
      });

      finalBatch.set(
        manualPlanRef,
        {
          selectedMemberIds,
          selectedTaskIds,
          selectionMode,
          appliedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      finalBatch.set(
        dashRef,
        {
          premiumFlags: {
            isPremium: false,
            showAds: true,
            canUseSmartDistribution: false,
            canUseVacations: false,
            canUseReviews: false,
            tier: downgraded.tier,
            maxMembers: downgraded.maxMembers,
            // Free no tiene plazas de pack → packs dormidos.
            memberPacks: { plus5: false, plus10: false },
          },
          adFlags: buildBannerAdFlags(true),
          rescueFlags: { isInRescue: false, daysLeft: null },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await finalBatch.commit();
      logger.info(`applyDowngradeJob: home ${homeId} downgraded (${selectionMode})`);
    } catch (err) {
      logger.error(`applyDowngradeJob: error processing home ${homeId}`, err);
    }
  }
});
