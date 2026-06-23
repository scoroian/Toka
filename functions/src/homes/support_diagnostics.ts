// functions/src/homes/support_diagnostics.ts
//
// Hallazgo #17 — Observabilidad de soporte.
// Callable READ-ONLY que permite a un agente de soporte autorizado inspeccionar
// el estado de UN hogar para diagnosticar el problema de un usuario, SIN exponer
// datos privados. Protegida por:
//   - App Check (enforceAppCheck) → la petición viene de un cliente legítimo.
//   - Custom claim `support: true` → solo cuentas de soporte autorizadas.
//
// PRIVACIDAD: el diagnóstico jamás devuelve teléfonos en claro, tokens FCM ni
// notas de valoración (privadas: solo autor y evaluado). Solo booleanos
// derivados (hasPhone/hasFcmToken) y la subcolección `reviews` NO se lee nunca.

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { toJsonSafe } from "../users/export_user_data";
import { getUserFcmToken } from "../notifications/fcm_tokens";
import { logEvent, newCorrelationId } from "../shared/log";

const UPCOMING_TASKS_LIMIT = 25;
const RECENT_EVENTS_LIMIT = 25;

// ── Tipos de entrada (datos ya leídos de Firestore por la callable) ──────────

export interface MemberDiagnosticInput {
  uid: string;
  /** Presencia del token en el doc privado users/{uid}; NUNCA el token en sí. */
  hasFcmToken: boolean;
  data: Record<string, unknown>;
}

export interface DocDiagnosticInput {
  id: string;
  data: Record<string, unknown>;
}

export interface DiagnosticsInput {
  homeId: string;
  homeData: Record<string, unknown> | undefined;
  members: MemberDiagnosticInput[];
  upcomingTasks: DocDiagnosticInput[];
  recentEvents: DocDiagnosticInput[];
}

// ── Autorización ─────────────────────────────────────────────────────────────

/**
 * ¿El token de auth lleva el claim de soporte? Debe ser booleano `true`
 * exacto (no la cadena "true") para evitar falsos positivos.
 */
export function hasSupportClaim(
  token: Record<string, unknown> | null | undefined
): boolean {
  return token?.["support"] === true;
}

// ── Construcción del diagnóstico (redacción) ─────────────────────────────────

function hasNonEmptyString(v: unknown): boolean {
  return typeof v === "string" && v.length > 0;
}

/**
 * Construye el objeto de diagnóstico REDACTADO a partir de los datos crudos.
 * Función pura (sin Firestore) para poder testear la redacción de forma aislada.
 */
export function buildHomeDiagnostics(input: DiagnosticsInput) {
  const h = input.homeData;
  const home = h
    ? {
        name: (h["name"] as string | undefined) ?? null,
        premiumStatus: (h["premiumStatus"] as string | undefined) ?? "free",
        premiumPlan: (h["premiumPlan"] as string | undefined) ?? null,
        premiumEndsAt: h["premiumEndsAt"] ?? null,
        restoreUntil: h["restoreUntil"] ?? null,
        ownerUid: (h["ownerUid"] as string | undefined) ?? null,
        currentPayerUid: (h["currentPayerUid"] as string | undefined) ?? null,
        lastPayerUid: (h["lastPayerUid"] as string | undefined) ?? null,
        autoRenewEnabled: (h["autoRenewEnabled"] as boolean | undefined) ?? null,
        timezone: (h["timezone"] as string | undefined) ?? null,
        createdAt: h["createdAt"] ?? null,
      }
    : null;

  const members = input.members.map((m) => {
    const d = m.data;
    return {
      uid: m.uid,
      nickname: (d["nickname"] as string | undefined) ?? null,
      role: (d["role"] as string | undefined) ?? null,
      status: (d["status"] as string | undefined) ?? null,
      billingState: (d["billingState"] as string | undefined) ?? null,
      // El factory escribe `tasksCompleted`; datos de test/legacy usan `completedCount`.
      tasksCompleted:
        (d["tasksCompleted"] as number | undefined) ??
        (d["completedCount"] as number | undefined) ??
        0,
      averageScore: (d["averageScore"] as number | undefined) ?? 0,
      ratingsCount: (d["ratingsCount"] as number | undefined) ?? 0,
      currentStreak: (d["currentStreak"] as number | undefined) ?? 0,
      complianceRate: (d["complianceRate"] as number | undefined) ?? null,
      passedCount: (d["passedCount"] as number | undefined) ?? 0,
      vacation: d["vacation"] ?? null,
      phoneVisibility: (d["phoneVisibility"] as string | undefined) ?? null,
      // REDACCIÓN: solo presencia, nunca el valor.
      hasPhone: hasNonEmptyString(d["phone"]),
      hasFcmToken: m.hasFcmToken,
    };
  });

  const upcomingTasks = input.upcomingTasks.map((t) => {
    const d = t.data;
    return {
      taskId: t.id,
      title: (d["title"] as string | undefined) ?? null,
      status: (d["status"] as string | undefined) ?? null,
      nextDueAt: d["nextDueAt"] ?? null,
      currentAssigneeUid: (d["currentAssigneeUid"] as string | undefined) ?? null,
      recurrenceType: (d["recurrenceType"] as string | undefined) ?? null,
    };
  });

  const recentEvents = input.recentEvents.map((e) => {
    const d = e.data;
    return {
      eventId: e.id,
      eventType: (d["eventType"] as string | undefined) ?? null,
      taskId: (d["taskId"] as string | undefined) ?? null,
      performerUid:
        (d["performerUid"] as string | undefined) ??
        (d["actorUid"] as string | undefined) ??
        null,
      createdAt: d["createdAt"] ?? null,
    };
  });

  return {
    homeId: input.homeId,
    home,
    memberCount: members.length,
    members,
    upcomingTasks,
    recentEvents,
  };
}

// ── Callable de diagnóstico (READ-ONLY) ──────────────────────────────────────

/**
 * Diagnóstico de soporte de UN hogar. READ-ONLY: no escribe nada en Firestore.
 *
 * Seguridad:
 *   - enforceAppCheck → la petición proviene de un cliente legítimo
 *     (Play Integrity / DeviceCheck). En tests, .run() omite esta capa.
 *   - claim `support: true` → solo cuentas de soporte autorizadas. Se concede
 *     con `admin.auth().setCustomUserClaims(uid, { support: true })`
 *     (ver secrets/qa_grant_support_claim.js).
 *
 * Devuelve el estado del hogar (premium, miembros, próximas tareas, últimos
 * eventos) REDACTADO: nunca teléfonos en claro, tokens FCM ni notas privadas.
 */
export const supportDiagnoseHome = onCall(
  { enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }
    if (!hasSupportClaim(request.auth.token as Record<string, unknown>)) {
      throw new HttpsError(
        "permission-denied",
        "Support claim required for diagnostics"
      );
    }

    const { homeId } = (request.data ?? {}) as { homeId?: string };
    if (!homeId) {
      throw new HttpsError("invalid-argument", "homeId is required");
    }

    const db = admin.firestore();
    const correlationId = newCorrelationId();
    const homeRef = db.collection("homes").doc(homeId);
    const homeSnap = await homeRef.get();
    if (!homeSnap.exists) {
      throw new HttpsError("not-found", "Home not found");
    }

    const [membersSnap, tasksSnap, eventsSnap] = await Promise.all([
      homeRef.collection("members").get(),
      homeRef
        .collection("tasks")
        .where("status", "==", "active")
        .orderBy("nextDueAt", "asc")
        .limit(UPCOMING_TASKS_LIMIT)
        .get(),
      homeRef
        .collection("taskEvents")
        .orderBy("createdAt", "desc")
        .limit(RECENT_EVENTS_LIMIT)
        .get(),
    ]);

    // Presencia (no valor) del token FCM, que vive en el doc PRIVADO users/{uid}.
    const members: MemberDiagnosticInput[] = await Promise.all(
      membersSnap.docs.map(async (d) => ({
        uid: d.id,
        data: d.data(),
        hasFcmToken: (await getUserFcmToken(d.id)) !== undefined,
      }))
    );

    const diagnostics = buildHomeDiagnostics({
      homeId,
      homeData: homeSnap.data(),
      members,
      upcomingTasks: tasksSnap.docs.map((d) => ({ id: d.id, data: d.data() })),
      recentEvents: eventsSnap.docs.map((d) => ({ id: d.id, data: d.data() })),
    });

    // Auditoría: queda registrado QUÉ agente de soporte consultó QUÉ hogar.
    logEvent("info", "support_diagnose_home", {
      homeId,
      uid: request.auth.uid,
      correlationId,
      memberCount: diagnostics.memberCount,
    });

    // toJsonSafe convierte los Timestamp a ISO-8601 (igual que exportUserData).
    return toJsonSafe({
      generatedAt: new Date().toISOString(),
      requestedBy: request.auth.uid,
      ...diagnostics,
    });
  }
);
