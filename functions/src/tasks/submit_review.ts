// functions/src/tasks/submit_review.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isPremium, FREE_LIMIT_CODES } from "../shared/free_limits";

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

  // 1. Verificar Premium del hogar (fuente de verdad: isPremium compartido)
  const homeSnap = await db.collection("homes").doc(homeId).get();
  if (!homeSnap.exists) throw new HttpsError("not-found", "Home not found");
  const homeData = homeSnap.data()!;
  const premiumStatus: string = homeData["premiumStatus"] ?? "free";
  if (!isPremium(premiumStatus)) {
    throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.reviews);
  }

  // 2. Verificar que el reviewer es miembro activo
  const reviewerMemberRef = db.collection("homes").doc(homeId).collection("members").doc(reviewerUid);
  const reviewerSnap = await reviewerMemberRef.get();
  if (!reviewerSnap.exists || reviewerSnap.data()!["status"] !== "active") {
    throw new HttpsError("permission-denied", "Reviewer must be an active member");
  }

  // Refs declarados fuera de la transacción para uso posterior (logging, etc.)
  const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc(taskEventId);
  const reviewRef = eventRef.collection("reviews").doc(reviewerUid);

  await db.runTransaction(async (tx) => {
    // ── Phase 1: ALL reads first ──────────────────────────────────────────────

    // Re-read event inside transaction for consistency
    const eventSnapTx = await tx.get(eventRef);
    if (!eventSnapTx.exists) throw new HttpsError("not-found", "Task event not found");
    const eventDataTx = eventSnapTx.data()!;
    if (eventDataTx["eventType"] !== "completed") {
      throw new HttpsError("failed-precondition", "Can only review completed events");
    }
    const performerUidTx: string = eventDataTx["performerUid"] ?? eventDataTx["actorUid"];
    const taskId: string = eventDataTx["taskId"];
    if (!taskId) throw new HttpsError("failed-precondition", "Event missing taskId");

    // No puede valorarse a sí mismo
    if (reviewerUid === performerUidTx) {
      throw new HttpsError("permission-denied", "Cannot review your own task");
    }

    // Duplicate check inside transaction
    const existingReviewTx = await tx.get(reviewRef);
    if (existingReviewTx.exists) {
      throw new HttpsError("already-exists", "You already reviewed this event");
    }

    // Pre-compute refs needed for reads
    const statsId = `${performerUidTx}_${taskId}`;
    const statsRef = db.collection("homes").doc(homeId).collection("memberTaskStats").doc(statsId);
    const performerRef = db.collection("homes").doc(homeId).collection("members").doc(performerUidTx);
    const memberReviewsRef = db.collection("homes").doc(homeId)
        .collection("memberReviews").doc(reviewerUid);

    // Read stats and performer docs before any writes
    const [statsSnap, performerSnap] = await Promise.all([
      tx.get(statsRef),
      tx.get(performerRef),
    ]);

    // ── Phase 2: ALL writes after reads ──────────────────────────────────────

    // Create review
    tx.set(reviewRef, {
      reviewerUid,
      performerUid: performerUidTx,
      score,
      note: note ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Update memberTaskStats
    const stats = statsSnap.data() ?? { avgScore: 0, reviewCount: 0 };
    const oldCount: number = (stats["reviewCount"] as number) ?? 0;
    const oldAvg: number = (stats["avgScore"] as number) ?? 0;
    const newCount = oldCount + 1;
    const newAvg = (oldAvg * oldCount + score) / newCount;

    tx.set(statsRef, {
      uid: performerUidTx,
      taskId,
      avgScore: newAvg,
      reviewCount: newCount,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // Update performer's avgReviewScore
    const performerData = performerSnap.data() ?? {};
    const pOldCount: number = (performerData["ratingsCount"] as number) ?? 0;
    const pOldAvg: number = (performerData["averageScore"] as number) ?? 0;
    const pNewCount = pOldCount + 1;
    const pNewAvg = (pOldAvg * pOldCount + score) / pNewCount;

    tx.set(performerRef, {
      averageScore: pNewAvg,
      ratingsCount: pNewCount,
    }, { merge: true });

    // Track ratedEventIds per reviewer to allow fast isRated checks in Flutter
    tx.set(memberReviewsRef, {
      ratedEventIds: FieldValue.arrayUnion(taskEventId),
    }, { merge: true });
  });

  logger.info(`submitReview: ${reviewerUid} reviewed event ${taskEventId} score=${score}`);
  return { success: true };
});
