// functions/test/integration/export_user_data.test.ts
//
// Verifica end-to-end (contra emuladores) la callable exportUserData (GDPR
// Art. 15/20, Hallazgo #04): devuelve el perfil, membresías, hogares con su
// doc de miembro y las reseñas escritas por el usuario; y rechaza sin auth.

import * as admin from "firebase-admin";
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  getDb,
  makeCallableRequest,
} from "./helpers/setup";
import { exportUserData } from "../../src/users/export_user_data";

// Llamamos .run() directamente (mismo patrón que el resto de tests de callables).
const wrapped = (req: any): Promise<any> => (exportUserData as any).run(req);

const HOME = "home-export";
const OWNER = "owner-export";
const SUBJECT = "subject-export"; // el usuario que exporta sus datos

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(SUBJECT, {
    nickname: "Sujeto QA",
    phone: "+34600999888",
    phoneVisibility: "sameHomeMembers",
    locale: "es",
    fcmToken: "subject-device-token",
  });
  await createHome(HOME, OWNER, { name: "Hogar Export", premiumStatus: "active" });
  await addMemberToHome(HOME, SUBJECT, "member", "active", {
    completedCount: 7,
    averageScore: 8.5,
  });

  // Una reseña ESCRITA por el sujeto sobre el owner.
  await getDb()
    .collection("homes").doc(HOME)
    .collection("taskEvents").doc("ev1")
    .set({ eventType: "completed", performerUid: OWNER, taskId: "t1" });
  await getDb()
    .collection("homes").doc(HOME)
    .collection("taskEvents").doc("ev1")
    .collection("reviews").doc(SUBJECT)
    .set({
      reviewerUid: SUBJECT,
      performerUid: OWNER,
      score: 9,
      note: "buen trabajo",
      createdAt: admin.firestore.Timestamp.now(),
    });
});

describe("exportUserData — happy path", () => {
  let result: any;
  beforeAll(async () => {
    result = await wrapped(makeCallableRequest(SUBJECT, {}));
  });

  it("incluye el perfil completo del propio usuario (incl. phone/locale)", () => {
    expect(result.uid).toBe(SUBJECT);
    expect(result.schemaVersion).toBe(1);
    expect(typeof result.exportedAt).toBe("string");
    expect(result.profile.nickname).toBe("Sujeto QA");
    expect(result.profile.phone).toBe("+34600999888");
    expect(result.profile.locale).toBe("es");
  });

  it("incluye las membresías del usuario", () => {
    const homeIds = result.memberships.map((m: any) => m.homeId);
    expect(homeIds).toContain(HOME);
  });

  it("incluye el hogar con su propio doc de miembro (rol/stats)", () => {
    const home = result.homes.find((h: any) => h.homeId === HOME);
    expect(home).toBeDefined();
    expect(home.homeName).toBe("Hogar Export");
    expect(home.member.role).toBe("member");
    expect(home.member.completedCount).toBe(7);
  });

  it("incluye las reseñas que ESCRIBIÓ el usuario, con Timestamp como ISO", () => {
    expect(result.reviewsAuthoredError).toBeNull(); // query OK en emulador
    expect(result.reviewsAuthored).toHaveLength(1);
    const r = result.reviewsAuthored[0];
    expect(r.reviewerUid).toBe(SUBJECT);
    expect(r.performerUid).toBe(OWNER);
    expect(r.score).toBe(9);
    expect(typeof r.createdAt).toBe("string"); // ISO, no {_seconds,...}
    expect(r.path).toContain(`reviews/${SUBJECT}`);
  });
});

describe("exportUserData — errores", () => {
  it("rechaza si no hay autenticación", async () => {
    await expect(
      wrapped({ data: {}, auth: null, rawRequest: {} })
    ).rejects.toThrow(/unauthenticated|Not authenticated/i);
  });

  it("usuario sin datos: devuelve estructura vacía sin lanzar", async () => {
    const res = await wrapped(makeCallableRequest("ghost-no-data", {}));
    expect(res.profile).toBeNull();
    expect(res.memberships).toEqual([]);
    expect(res.homes).toEqual([]);
    expect(res.reviewsAuthored).toEqual([]);
  });
});
