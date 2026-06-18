// functions/test/integration/cleanup_user.test.ts
//
// Verifica end-to-end (contra emuladores) la limpieza tras borrar una cuenta:
// miembro→left, traspaso de owner, hogar huérfano, liberación del pagador,
// reasignación de tareas y borrado de users/{uid}. Requiere emuladores
// (firebase emulators:start) — ver jest.integration.config.js.

import * as admin from "firebase-admin";
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
} from "./helpers/setup";
import { cleanupDeletedUser } from "../../src/users/cleanup_user";

function futureDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + days * 24 * 60 * 60 * 1000)
  );
}

beforeAll(async () => {
  await cleanAll();
});

// ---------------------------------------------------------------------------
describe("cleanupDeletedUser — miembro normal", () => {
  const HOME = "home-cleanup-member";
  const OWNER = "owner-cm";
  const MEMBER = "member-cm";

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(MEMBER);
    await createHome(HOME, OWNER, { premiumStatus: "free" });
    await addMemberToHome(HOME, MEMBER, "member", "active");
    // Tarea cuyo responsable actual es el miembro que se borra.
    await createTask(HOME, "task-cm", MEMBER, {
      assignmentOrder: [MEMBER, OWNER],
      currentAssigneeUid: MEMBER,
    });
    await cleanupDeletedUser(MEMBER);
  });

  it("marca el documento de miembro como left + accountDeleted (snapshot conservado)", async () => {
    const doc = await getDb().collection("homes").doc(HOME).collection("members").doc(MEMBER).get();
    expect(doc.exists).toBe(true);
    expect(doc.data()!["status"]).toBe("left");
    expect(doc.data()!["accountDeleted"]).toBe(true);
  });

  it("borra users/{uid} y sus memberships", async () => {
    const userDoc = await getDb().collection("users").doc(MEMBER).get();
    expect(userDoc.exists).toBe(false);
    const mems = await getDb().collection("users").doc(MEMBER).collection("memberships").get();
    expect(mems.empty).toBe(true);
  });

  it("reasigna la tarea al owner y lo quita del assignmentOrder", async () => {
    const task = await getDb().collection("homes").doc(HOME).collection("tasks").doc("task-cm").get();
    expect(task.data()!["currentAssigneeUid"]).toBe(OWNER);
    expect(task.data()!["assignmentOrder"]).toEqual([OWNER]);
  });

  it("NO emite taskEvents de reasignación (evita 'completados' fantasma en historial)", async () => {
    const evs = await getDb()
      .collection("homes").doc(HOME).collection("taskEvents").get();
    expect(evs.size).toBe(0);
  });

  it("el dashboard recuenta miembros activos (excluye al borrado)", async () => {
    const dash = await getDb().collection("homes").doc(HOME).collection("views").doc("dashboard").get();
    expect(dash.data()!["counters"]["totalMembers"]).toBe(1);
    const previewUids = (dash.data()!["memberPreview"] as { uid: string }[]).map((p) => p.uid);
    expect(previewUids).toEqual([OWNER]);
  });

  it("el owner sigue siendo owner", async () => {
    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["ownerUid"]).toBe(OWNER);
  });
});

// ---------------------------------------------------------------------------
describe("cleanupDeletedUser — owner + pagador con sustituto", () => {
  const HOME = "home-cleanup-owner";
  const OWNER = "owner-co";
  const ADMIN = "admin-co";
  const MEMBER = "member-co";

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(ADMIN);
    await createUser(MEMBER);
    await createHome(HOME, OWNER, {
      premiumStatus: "active",
      currentPayerUid: OWNER,
      autoRenewEnabled: true,
      premiumEndsAt: futureDate(20),
    });
    await addMemberToHome(HOME, ADMIN, "admin", "active");
    await addMemberToHome(HOME, MEMBER, "member", "active");
    await cleanupDeletedUser(OWNER);
  });

  it("traspasa la propiedad al admin (preferido sobre member)", async () => {
    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["ownerUid"]).toBe(ADMIN);
    const adminMember = await getDb().collection("homes").doc(HOME).collection("members").doc(ADMIN).get();
    expect(adminMember.data()!["role"]).toBe("owner");
    const adminMembership = await getDb().collection("users").doc(ADMIN).collection("memberships").doc(HOME).get();
    expect(adminMembership.data()!["role"]).toBe("owner");
  });

  it("libera al pagador y corta auto-renovación, conservando el periodo pagado", async () => {
    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["currentPayerUid"]).toBeNull();
    expect(home.data()!["autoRenewEnabled"]).toBe(false);
    expect(home.data()!["lastPayerUid"]).toBe(OWNER);
    // El periodo Premium ya pagado se respeta: status y fin intactos.
    expect(home.data()!["premiumStatus"]).toBe("active");
    expect(home.data()!["premiumEndsAt"]).not.toBeNull();
  });

  it("el ex-owner queda como left", async () => {
    const doc = await getDb().collection("homes").doc(HOME).collection("members").doc(OWNER).get();
    expect(doc.data()!["status"]).toBe("left");
  });
});

// ---------------------------------------------------------------------------
describe("cleanupDeletedUser — owner único → hogar huérfano", () => {
  const HOME = "home-cleanup-solo";
  const SOLO = "owner-solo";

  beforeAll(async () => {
    await createUser(SOLO);
    await createHome(HOME, SOLO, { premiumStatus: "free" });
    await cleanupDeletedUser(SOLO);
  });

  it("marca el hogar como purged y sin owner", async () => {
    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["premiumStatus"]).toBe("purged");
    expect(home.data()!["ownerUid"]).toBeNull();
  });

  it("borra el usuario", async () => {
    const userDoc = await getDb().collection("users").doc(SOLO).get();
    expect(userDoc.exists).toBe(false);
  });
});

// ---------------------------------------------------------------------------
describe("cleanupDeletedUser — idempotente", () => {
  const HOME = "home-cleanup-idem";
  const OWNER = "owner-idem";
  const MEMBER = "member-idem";

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(MEMBER);
    await createHome(HOME, OWNER, { premiumStatus: "free" });
    await addMemberToHome(HOME, MEMBER, "member", "active");
    await cleanupDeletedUser(MEMBER);
  });

  it("re-ejecutar sobre una cuenta ya limpiada no lanza ni cambia el estado", async () => {
    await expect(cleanupDeletedUser(MEMBER)).resolves.toBeUndefined();
    const doc = await getDb().collection("homes").doc(HOME).collection("members").doc(MEMBER).get();
    expect(doc.data()!["status"]).toBe("left");
    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["ownerUid"]).toBe(OWNER);
  });
});
