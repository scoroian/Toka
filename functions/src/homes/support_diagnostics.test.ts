// functions/src/homes/support_diagnostics.test.ts
//
// Hallazgo #17: callable de diagnóstico de soporte (READ-ONLY). Aquí se testea
// la lógica PURA: (1) el gate de autorización por claim de soporte y (2) la
// REDACCIÓN del diagnóstico — la propiedad de seguridad clave: el resultado
// NUNCA contiene teléfono en claro, token FCM ni notas privadas; solo booleanos
// derivados. El acceso a Firestore y App Check se ejercitan en integración.

import { hasSupportClaim, buildHomeDiagnostics } from "./support_diagnostics";

describe("hasSupportClaim", () => {
  it("token con support === true → true", () => {
    expect(hasSupportClaim({ support: true, uid: "x" })).toBe(true);
  });

  it("support no booleano (string 'true') → false", () => {
    expect(hasSupportClaim({ support: "true" })).toBe(false);
  });

  it("support false / ausente → false", () => {
    expect(hasSupportClaim({ support: false })).toBe(false);
    expect(hasSupportClaim({ uid: "x" })).toBe(false);
  });

  it("token nulo/undefined → false (defensivo)", () => {
    expect(hasSupportClaim(null)).toBe(false);
    expect(hasSupportClaim(undefined)).toBe(false);
  });
});

describe("buildHomeDiagnostics — mapeo (happy path)", () => {
  const out = buildHomeDiagnostics({
    homeId: "home-1",
    homeData: {
      name: "Casa QA",
      premiumStatus: "active",
      premiumPlan: "yearly",
      premiumEndsAt: "2026-12-01T00:00:00.000Z",
      restoreUntil: null,
      ownerUid: "owner",
      currentPayerUid: "owner",
      lastPayerUid: "owner",
      autoRenewEnabled: true,
      timezone: "Europe/Madrid",
      createdAt: "2026-01-01T00:00:00.000Z",
    },
    members: [
      {
        uid: "owner",
        hasFcmToken: true,
        data: {
          nickname: "Dueño",
          role: "owner",
          status: "active",
          billingState: "currentPayer",
          tasksCompleted: 12,
          averageScore: 8.4,
          ratingsCount: 5,
          currentStreak: 3,
          complianceRate: 0.9,
          passedCount: 1,
          vacation: null,
          phone: "+34600111222",
          phoneVisibility: "sameHomeMembers",
        },
      },
    ],
    upcomingTasks: [
      {
        id: "t1",
        data: {
          title: "Fregar",
          status: "active",
          nextDueAt: "2026-06-22T18:00:00.000Z",
          currentAssigneeUid: "owner",
          recurrenceType: "weekly",
        },
      },
    ],
    recentEvents: [
      {
        id: "ev1",
        data: {
          eventType: "completed",
          taskId: "t1",
          performerUid: "owner",
          createdAt: "2026-06-21T18:00:00.000Z",
        },
      },
    ],
  });

  it("mapea la cabecera del hogar (premium/owner/payer/fechas)", () => {
    expect(out.homeId).toBe("home-1");
    expect(out.home).not.toBeNull();
    expect(out.home!.name).toBe("Casa QA");
    expect(out.home!.premiumStatus).toBe("active");
    expect(out.home!.premiumPlan).toBe("yearly");
    expect(out.home!.ownerUid).toBe("owner");
    expect(out.home!.currentPayerUid).toBe("owner");
    expect(out.home!.timezone).toBe("Europe/Madrid");
  });

  it("mapea miembros, tareas próximas y eventos recientes", () => {
    expect(out.memberCount).toBe(1);
    expect(out.members[0].uid).toBe("owner");
    expect(out.members[0].role).toBe("owner");
    expect(out.members[0].tasksCompleted).toBe(12);
    expect(out.members[0].averageScore).toBe(8.4);
    expect(out.upcomingTasks[0].taskId).toBe("t1");
    expect(out.upcomingTasks[0].title).toBe("Fregar");
    expect(out.recentEvents[0].eventId).toBe("ev1");
    expect(out.recentEvents[0].performerUid).toBe("owner");
  });
});

describe("buildHomeDiagnostics — REDACCIÓN de PII (propiedad de seguridad)", () => {
  const out = buildHomeDiagnostics({
    homeId: "home-2",
    homeData: { name: "Casa", premiumStatus: "free", ownerUid: "o" },
    members: [
      {
        uid: "m1",
        hasFcmToken: true, // tiene token en users/{uid}
        data: {
          nickname: "Miembro",
          role: "member",
          status: "active",
          phone: "+34600999000", // teléfono presente (visible para co-miembros)
          phoneVisibility: "sameHomeMembers",
          fcmToken: "NO-DEBE-SALIR", // por si un doc viejo aún lo tuviera
        },
      },
      {
        uid: "m2",
        hasFcmToken: false,
        data: {
          nickname: "Sin tel",
          role: "member",
          status: "active",
          phone: null,
          phoneVisibility: "hidden",
        },
      },
    ],
    upcomingTasks: [],
    recentEvents: [],
  });

  it("expone hasPhone/hasFcmToken como booleanos, NUNCA el valor", () => {
    const m1 = out.members[0];
    expect(m1.hasPhone).toBe(true);
    expect(m1.hasFcmToken).toBe(true);
    expect(m1.phoneVisibility).toBe("sameHomeMembers");
    // Las claves sensibles NO existen en la salida:
    expect(m1).not.toHaveProperty("phone");
    expect(m1).not.toHaveProperty("fcmToken");

    const m2 = out.members[1];
    expect(m2.hasPhone).toBe(false);
    expect(m2.hasFcmToken).toBe(false);
  });

  it("ningún VALOR sensible (teléfono, token, nota) aparece en el JSON serializado", () => {
    const json = JSON.stringify(out);
    // El número de teléfono en claro no debe aparecer:
    expect(json).not.toContain("+34600999000");
    // El valor del token FCM no debe aparecer (el campo booleano hasFcmToken sí,
    // pero solo expone presencia, no el token):
    expect(json).not.toContain("NO-DEBE-SALIR");
    // No existe ninguna clave `note` (las notas de valoración viven en la
    // subcolección `reviews`, que el diagnóstico no lee):
    expect(json).not.toContain("\"note\"");
  });
});

describe("buildHomeDiagnostics — edge: hogar inexistente / vacío", () => {
  it("homeData undefined → home null y colecciones vacías sin lanzar", () => {
    const out = buildHomeDiagnostics({
      homeId: "ghost",
      homeData: undefined,
      members: [],
      upcomingTasks: [],
      recentEvents: [],
    });
    expect(out.home).toBeNull();
    expect(out.members).toEqual([]);
    expect(out.memberCount).toBe(0);
    expect(out.upcomingTasks).toEqual([]);
    expect(out.recentEvents).toEqual([]);
  });
});
