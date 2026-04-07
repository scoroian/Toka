// functions/src/tasks/submit_review.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const submitReview = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskEventId, score, note } = request.data as {
    homeId: string;
    taskEventId: string;
    score: number;
    note?: string;
  };
  const reviewerUid = request.auth.uid;

  if (!homeId || !taskEventId) {
    throw new HttpsError("invalid-argument", "homeId and taskEventId required");
  }
  if (typeof score !== "number" || score < 1 || score > 10) {
    throw new HttpsError("invalid-argument", "score must be between 1 and 10");
  }
  if (note && note.length > 300) {
    throw new HttpsError("invalid-argument", "note exceeds 300 characters");
  }

  // 1. Verificar Premium del hogar
  const homeSnap = await db.collection("homes").doc(homeId).get();
  if (!homeSnap.exists) throw new HttpsError("not-found", "Home not found");
  const homeData = homeSnap.data()!;
  const premiumStatus: string = homeData["premiumStatus"] ?? "free";
  if (!["active", "cancelled_pending_end", "rescue"].includes(premiumStatus)) {
    throw new HttpsError("failed-precondition", "Reviews require Premium");
  }

  // 2. Leer el evento completed
  const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc(taskEventId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) throw new HttpsError("not-found", "Task event not found");

  const eventData = eventSnap.data()!;
  if (eventData["eventType"] !== "completed") {
    throw new HttpsError("failed-precondition", "Can only review completed events");
  }
  const performerUid: string = eventData["performerUid"] ?? eventData["actorUid"];

  // 3. No puede valorarse a sí mismo
  if (reviewerUid === performerUid) {
    throw new HttpsError("permission-denied", "Cannot review your own task");
  }

  // 4. Verificar que el reviewer es miembro activo
  const reviewerMemberRef = db.collection("homes").doc(homeId).collection("members").doc(reviewerUid);
  const reviewerSnap = await reviewerMemberRef.get();
  if (!reviewerSnap.exists || reviewerSnap.data()!["status"] !== "active") {
    throw new HttpsError("permission-denied", "Reviewer must be an active member");
  }

  // 5. Verificar duplicado
  const reviewRef = eventRef.collection("reviews").doc(reviewerUid);
  const existingReview = await reviewRef.get();
  if (existingReview.exists) {
    throw new HttpsError("already-exists", "You already reviewed this event");
  }

  await db.runTransaction(async (tx) => {
    // 6. Crear review
    tx.set(reviewRef, {
      reviewerUid,
      performerUid,
      score,
      note: note ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // 7. Actualizar memberTaskStats
    const taskId: string = eventData["taskId"];
    const statsId = `${performerUid}_${taskId}`;
    const statsRef = db.collection("homes").doc(homeId).collection("memberTaskStats").doc(statsId);
    const statsSnap = await tx.get(statsRef);
    const stats = statsSnap.data() ?? { avgScore: 0, reviewCount: 0 };
    const oldCount: number = (stats["reviewCount"] as number) ?? 0;
    const oldAvg: number = (stats["avgScore"] as number) ?? 0;
    const newCount = oldCount + 1;
    const newAvg = (oldAvg * oldCount + score) / newCount;

    tx.set(statsRef, {
      uid: performerUid,
      taskId,
      avgScore: newAvg,
      reviewCount: newCount,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // 8. Actualizar avgReviewScore del miembro
    const performerRef = db.collection("homes").doc(homeId).collection("members").doc(performerUid);
    const performerSnap = await tx.get(performerRef);
    const performerData = performerSnap.data() ?? {};
    const pOldCount: number = (performerData["reviewCount"] as number) ?? 0;
    const pOldAvg: number = (performerData["avgReviewScore"] as number) ?? 0;
    const pNewCount = pOldCount + 1;
    const pNewAvg = (pOldAvg * pOldCount + score) / pNewCount;

    tx.update(performerRef, {
      avgReviewScore: pNewAvg,
      reviewCount: pNewCount,
    });
  });

  logger.info(`submitReview: ${reviewerUid} reviewed event ${taskEventId} score=${score}`);
  return { success: true };
});
