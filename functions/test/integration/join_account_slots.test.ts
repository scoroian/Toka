// functions/test/integration/join_account_slots.test.ts
//
// Hallazgo #01 (lote UX 2026-06-25) — joinHome/joinHomeByCode deben validar las
// PLAZAS DE CUENTA del invitado, no solo el tope de miembros del hogar destino.
//
// Bug: createHome cuenta las memberships activas del usuario contra su cap de
// cuenta (baseHomeSlots + lifetimeUnlockedHomeSlots, máx homeSlotCap = 5), pero
// joinHome/joinHomeByCode solo aplicaban enforceMemberCapTx (tope del HOGAR).
// Resultado: un usuario ya en 5 hogares podía unirse a un 6º por invitación,
// eludiendo el cap de cuenta (las plazas de hogar son el eje monetizable).
//
// Aquí ejercitamos las callables REALES contra el emulador de Firestore.

import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import * as admin from 'firebase-admin';
import { joinHome, joinHomeByCode } from '../../src/homes/index';

const runJoin = (req: any): Promise<any> => (joinHome as any).run(req);
const runJoinByCode = (req: any): Promise<any> => (joinHomeByCode as any).run(req);

function futureTs(): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));
}

/** Crea `count` memberships ACTIVAS de relleno para `uid` (ocupan plaza de cuenta). */
async function seedActiveMemberships(uid: string, count: number): Promise<void> {
  const db = getDb();
  const batch = db.batch();
  for (let i = 0; i < count; i++) {
    batch.set(
      db.collection('users').doc(uid).collection('memberships').doc(`seed-${uid}-${i}`),
      { role: 'member', status: 'active' },
    );
  }
  await batch.commit();
}

/** Nº de memberships activas del usuario (mismo cómputo que el cap de cuenta). */
async function activeMembershipCount(uid: string): Promise<number> {
  const snap = await getDb()
    .collection('users').doc(uid).collection('memberships')
    .where('status', '==', 'active')
    .get();
  return snap.size;
}

async function memberStatus(homeId: string, uid: string): Promise<string | undefined> {
  const d = await getDb()
    .collection('homes').doc(homeId).collection('members').doc(uid).get();
  return d.data()?.['status'] as string | undefined;
}

/** Crea una invitación con código en el hogar y devuelve {invId, code}. */
async function createInvitation(homeId: string, code: string): Promise<string> {
  const invRef = getDb()
    .collection('homes').doc(homeId).collection('invitations').doc();
  await invRef.set({ code, used: false, expiresAt: futureTs() });
  return invRef.id;
}

const OWNER = 'slots-owner';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER, { nickname: 'Owner' });
});

// ---------------------------------------------------------------------------
describe('joinHomeByCode — cap de plazas de cuenta del invitado', () => {
  it('cuenta con 1 plaza libre se une correctamente', async () => {
    const HOME = 'slots-ok-home';
    const JOINER = 'slots-ok-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'Libre' }); // homeSlotCap=5 por defecto
    await seedActiveMemberships(JOINER, 4); // 4 activas → 1 plaza libre
    const code = 'OKJOIN';
    await createInvitation(HOME, code);

    const res = await runJoinByCode(makeCallableRequest(JOINER, { code }));

    expect(res.homeId).toBe(HOME);
    expect(await memberStatus(HOME, JOINER)).toBe('active');
    expect(await activeMembershipCount(JOINER)).toBe(5);
  });

  it('cuenta al límite (5 hogares activos) se une a un 6º → resource-exhausted / no-account-slots', async () => {
    const HOME = 'slots-full-home';
    const JOINER = 'slots-full-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'Lleno' });
    await seedActiveMemberships(JOINER, 5); // al límite
    const code = 'FULLJN';
    await createInvitation(HOME, code);

    await expect(
      runJoinByCode(makeCallableRequest(JOINER, { code })),
    ).rejects.toMatchObject({ code: 'resource-exhausted', message: 'no-account-slots' });

    // No se creó el miembro ni se consumió la invitación (rollback de la tx).
    expect(await memberStatus(HOME, JOINER)).toBeUndefined();
    expect(await activeMembershipCount(JOINER)).toBe(5);
  });

  it('REJOIN: volver a un hogar del que eras miembro (left) estando al límite → permitido, sin consumir plaza', async () => {
    const HOME = 'slots-rejoin-home';
    const JOINER = 'slots-rejoin-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'Vuelve' });
    // 5 plazas OCUPADAS por OTROS hogares (al límite).
    await seedActiveMemberships(JOINER, 5);
    // Y un doc de miembro previo en HOME, ya abandonado (status 'left').
    await addMemberToHome(HOME, JOINER, 'member', 'left');
    const code = 'REJOIN';
    await createInvitation(HOME, code);

    // Rejoin NO debe bloquearse aunque la cuenta esté al límite.
    await runJoinByCode(makeCallableRequest(JOINER, { code }));

    expect(await memberStatus(HOME, JOINER)).toBe('active');
  });

  it('coexistencia: hogar Free LLENO pero cuenta con plazas → failed-precondition (tope del hogar, no de cuenta)', async () => {
    const HOME = 'slots-homefull';
    const JOINER = 'slots-homefull-joiner';
    // Hogar Free (tope 3 miembros): owner + 2 ya lo llenan.
    await createHome(HOME, OWNER);
    await addMemberToHome(HOME, 'hf-m1', 'member', 'active');
    await addMemberToHome(HOME, 'hf-m2', 'member', 'active');
    await createUser(JOINER, { nickname: 'ConPlazas' }); // 0 memberships → plazas libres
    const code = 'HOMEFL';
    await createInvitation(HOME, code);

    await expect(
      runJoinByCode(makeCallableRequest(JOINER, { code })),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberStatus(HOME, JOINER)).toBeUndefined();
  });

  it('concurrencia: con 1 plaza libre, 3 joins simultáneos a 3 hogares → solo 1 tiene éxito', async () => {
    const JOINER = 'slots-race-joiner';
    await createUser(JOINER, { nickname: 'Carrera' });
    await seedActiveMemberships(JOINER, 4); // 1 plaza libre
    const homes = ['slots-race-a', 'slots-race-b', 'slots-race-c'];
    const codes = ['RACEAA', 'RACEBB', 'RACECC'];
    for (let i = 0; i < homes.length; i++) {
      await createHome(homes[i], OWNER);
      await createInvitation(homes[i], codes[i]);
    }

    const results = await Promise.allSettled(
      codes.map((code) => runJoinByCode(makeCallableRequest(JOINER, { code }))),
    );
    const fulfilled = results.filter((r) => r.status === 'fulfilled');

    // La transacción impide cruzar el cap: a lo sumo 1 éxito y el total de
    // memberships activas no supera las 5 plazas.
    expect(fulfilled.length).toBe(1);
    expect(await activeMembershipCount(JOINER)).toBe(5);
  });
});

// ---------------------------------------------------------------------------
describe('joinHome — cap de plazas de cuenta del invitado', () => {
  it('cuenta con plaza libre se une correctamente', async () => {
    const HOME = 'slots-jh-ok';
    const JOINER = 'slots-jh-ok-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'JH Libre' });
    await seedActiveMemberships(JOINER, 4);
    const invId = await createInvitation(HOME, 'JHOK01');

    await runJoin(makeCallableRequest(JOINER, { homeId: HOME, invitationId: invId }));
    expect(await memberStatus(HOME, JOINER)).toBe('active');
  });

  it('cuenta al límite → resource-exhausted / no-account-slots', async () => {
    const HOME = 'slots-jh-full';
    const JOINER = 'slots-jh-full-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'JH Lleno' });
    await seedActiveMemberships(JOINER, 5);
    const invId = await createInvitation(HOME, 'JHFULL');

    await expect(
      runJoin(makeCallableRequest(JOINER, { homeId: HOME, invitationId: invId })),
    ).rejects.toMatchObject({ code: 'resource-exhausted', message: 'no-account-slots' });
    expect(await memberStatus(HOME, JOINER)).toBeUndefined();
  });

  it('REJOIN estando al límite → permitido', async () => {
    const HOME = 'slots-jh-rejoin';
    const JOINER = 'slots-jh-rejoin-joiner';
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'JH Vuelve' });
    await seedActiveMemberships(JOINER, 5);
    await addMemberToHome(HOME, JOINER, 'member', 'left');
    const invId = await createInvitation(HOME, 'JHREJO');

    await runJoin(makeCallableRequest(JOINER, { homeId: HOME, invitationId: invId }));
    expect(await memberStatus(HOME, JOINER)).toBe('active');
  });

  it('respeta plazas extra desbloqueadas (homeSlotCap mayor)', async () => {
    const HOME = 'slots-jh-cap';
    const JOINER = 'slots-jh-cap-joiner';
    await createHome(HOME, OWNER);
    // Usuario con 1 plaza extra comprada (cap 6) y 5 activas → aún tiene hueco.
    await createUser(JOINER, {
      nickname: 'JH Cap',
      baseHomeSlots: 2,
      lifetimeUnlockedHomeSlots: 4,
      homeSlotCap: 6,
    });
    await seedActiveMemberships(JOINER, 5);
    const invId = await createInvitation(HOME, 'JHCAP1');

    await runJoin(makeCallableRequest(JOINER, { homeId: HOME, invitationId: invId }));
    expect(await memberStatus(HOME, JOINER)).toBe('active');
    expect(await activeMembershipCount(JOINER)).toBe(6);
  });
});
