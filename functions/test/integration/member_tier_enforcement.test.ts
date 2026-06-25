// functions/test/integration/member_tier_enforcement.test.ts
//
// Enforcement SERVER-SIDE del tope de miembros por tier al unirse (joinHome).
// El tope se deriva del tier (flag ON) o del binario 10/3 (flag OFF) y se
// aplica también a hogares premium (antes solo se enforce el Free).
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb, makeCallableRequest,
} from './helpers/setup';
import * as admin from 'firebase-admin';
import { joinHome } from '../../src/homes/index';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';

const wrappedJoin = (req: any): Promise<any> => (joinHome as any).run(req);
const OWNER = 'owner-enf';
const Timestamp = admin.firestore.Timestamp;

async function seedHome(
  homeId: string, premiumStatus: string, tier: string | null, maxMembers: number, extraActive: number,
): Promise<void> {
  await createHome(homeId, OWNER, {
    premiumStatus,
    premiumTier: tier,
    limits: { maxMembers, maxTasks: 50 },
  });
  for (let i = 0; i < extraActive; i++) {
    await addMemberToHome(homeId, `${homeId}-m${i}`, 'member', 'active');
  }
}

async function attemptJoin(homeId: string, joinerUid: string): Promise<any> {
  await createUser(joinerUid);
  const invId = `${homeId}-inv-${joinerUid}`;
  await getDb().collection('homes').doc(homeId).collection('invitations').doc(invId)
    .set({ used: false, createdBy: OWNER });
  return wrappedJoin(makeCallableRequest(joinerUid, { homeId, invitationId: invId }));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
});

afterAll(() => __setHomeTiersEnabledForTesting(undefined));

describe('enforcement flag ON — tope por tier', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  // [tier, premiumStatus, maxMembers, activosAntesDeUnirse(incluido owner)]
  const tiers: Array<[string, string, number]> = [
    ['free', 'free', 3],
    ['pareja', 'active', 2],
    ['familia', 'active', 5],
    ['grupo', 'active', 10],
  ];

  it.each(tiers)('%s: unirse en tope-1 → OK', async (tier, status, max) => {
    const HOME = `enf-ok-${tier}`;
    // activos = max-1 (owner + (max-2) miembros); el que se une llega justo al tope.
    await seedHome(HOME, status, tier === 'free' ? null : tier, max, max - 2);
    await expect(attemptJoin(HOME, `joiner-ok-${tier}`)).resolves.toBeUndefined();
    const active = await getDb().collection('homes').doc(HOME)
      .collection('members').where('status', '==', 'active').get();
    expect(active.size).toBe(max);
  });

  it.each(tiers)('%s: unirse en el tope → rechazo server-side (free_limit_members)', async (tier, status, max) => {
    const HOME = `enf-reject-${tier}`;
    // activos = max (owner + (max-1) miembros); el siguiente debe ser rechazado.
    await seedHome(HOME, status, tier === 'free' ? null : tier, max, max - 1);
    await expect(attemptJoin(HOME, `joiner-rej-${tier}`)).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'free_limit_members',
    });
  });

  it('el rechazo incluye details {maxMembers, tier}', async () => {
    const HOME = 'enf-details';
    await seedHome(HOME, 'active', 'pareja', 2, 1); // owner + 1 = 2 = tope
    await expect(attemptJoin(HOME, 'joiner-details')).rejects.toMatchObject({
      details: { maxMembers: 2, tier: 'pareja' },
    });
  });
});

describe('enforcement flag OFF — binario (premium 10 / free 3)', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(false));

  it('hogar con SKU Pareja pero flag OFF → tope 10 (no se rechaza el 4º)', async () => {
    const HOME = 'enf-flagoff-premium';
    await seedHome(HOME, 'active', 'pareja', 2, 3); // owner + 2 = 3 activos
    await expect(attemptJoin(HOME, 'joiner-flagoff')).resolves.toBeUndefined();
  });

  it('hogar free flag OFF → tope 3 se sigue aplicando', async () => {
    const HOME = 'enf-flagoff-free';
    await seedHome(HOME, 'free', null, 3, 2); // owner + 2 = 3 activos
    await expect(attemptJoin(HOME, 'joiner-flagoff-free')).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'free_limit_members',
    });
  });
});

describe('enforcement con packs de miembro (Grupo + packs)', () => {
  const FUTURE = () => Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z'));
  const PACK_ACTIVE = (chargeId: string) => ({ status: 'active', active: true, chargeId, endsAt: FUTURE() });

  async function seedGrupoPacks(
    homeId: string, packs: Record<string, unknown>, maxMembers: number, extraActive: number,
  ): Promise<void> {
    await createHome(homeId, OWNER, {
      premiumStatus: 'active', premiumTier: 'grupo',
      limits: { maxMembers, maxTasks: 50 }, memberPacks: packs,
    });
    for (let i = 0; i < extraActive; i++) {
      await addMemberToHome(homeId, `${homeId}-m${i}`, 'member', 'active');
    }
  }

  beforeEach(() => {
    __setHomeTiersEnabledForTesting(true);
    __setMemberPacksEnabledForTesting(true);
  });
  afterAll(() => __setMemberPacksEnabledForTesting(undefined));

  it('Grupo + +5: tope efectivo 15, unirse en 14 → OK', async () => {
    const HOME = 'enf-pack5-ok';
    await seedGrupoPacks(HOME, { plus5: PACK_ACTIVE('c5') }, 15, 13); // 14 activos
    await expect(attemptJoin(HOME, 'joiner-p5-ok')).resolves.toBeUndefined();
    const active = await getDb().collection('homes').doc(HOME).collection('members').where('status', '==', 'active').get();
    expect(active.size).toBe(15);
  });

  it('Grupo + +5 y +10: tope 25, unirse en 24 → OK', async () => {
    const HOME = 'enf-pack25-ok';
    await seedGrupoPacks(HOME, { plus5: PACK_ACTIVE('c5'), plus10: PACK_ACTIVE('c10') }, 25, 23); // 24 activos
    await expect(attemptJoin(HOME, 'joiner-25-ok')).resolves.toBeUndefined();
    const active = await getDb().collection('homes').doc(HOME).collection('members').where('status', '==', 'active').get();
    expect(active.size).toBe(25);
  });

  it('Grupo + +5 y +10: unirse en 25 → rechazo (tope absoluto 25), details {25, grupo}', async () => {
    const HOME = 'enf-pack26-reject';
    await seedGrupoPacks(HOME, { plus5: PACK_ACTIVE('c5'), plus10: PACK_ACTIVE('c10') }, 25, 24); // 25 activos
    await expect(attemptJoin(HOME, 'joiner-26-rej')).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'free_limit_members',
      details: { maxMembers: 25, tier: 'grupo' },
    });
  });

  it('flag de packs OFF → tope vuelve a 10 (Grupo) aunque haya packs: unirse en 10 → rechazo', async () => {
    __setMemberPacksEnabledForTesting(false);
    const HOME = 'enf-pack-flagoff';
    await seedGrupoPacks(HOME, { plus5: PACK_ACTIVE('c5'), plus10: PACK_ACTIVE('c10') }, 25, 9); // 10 activos
    await expect(attemptJoin(HOME, 'joiner-pack-off')).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'free_limit_members',
      details: { maxMembers: 10, tier: 'grupo' },
    });
  });
});
