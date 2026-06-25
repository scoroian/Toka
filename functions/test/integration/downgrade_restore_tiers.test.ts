// functions/test/integration/downgrade_restore_tiers.test.ts
//
// Cron de downgrade a Free (tier 'free'/tope 3 en dashboard, premiumTier sticky)
// y restore (recupera el tope del tier sticky, descongela).
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { applyDowngradeJob } from '../../src/entitlement/apply_downgrade_plan';
import { restorePremiumState } from '../../src/jobs/restore_premium_state';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';

const Timestamp = admin.firestore.Timestamp;
const runCron = (): Promise<any> => (applyDowngradeJob as any).run({});
const runRestore = (req: any): Promise<any> => (restorePremiumState as any).run(req);

function pastDate(days: number) {
  return Timestamp.fromDate(new Date(Date.now() - days * 24 * 3600 * 1000));
}

async function countByStatus(homeId: string, status: string): Promise<number> {
  const snap = await getDb().collection('homes').doc(homeId)
    .collection('members').where('status', '==', status).get();
  return snap.size;
}

const OWNER = 'owner-dgr';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
});

afterAll(() => __setHomeTiersEnabledForTesting(undefined));

describe('applyDowngradeJob — downgrade a Free expone tier/maxMembers', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  it('expira un Grupo → Free(3): dashboard tier free/3, premiumTier sticky preservado', async () => {
    const HOME = 'dgr-cron';
    await createHome(HOME, OWNER, {
      premiumStatus: 'active',
      premiumTier: 'grupo',
      premiumEndsAt: pastDate(1),
      limits: { maxMembers: 10, maxTasks: 50 },
    });
    // owner + 4 = 5 activos → debe quedar en 3 (owner + 2)
    for (let i = 0; i < 4; i++) {
      await addMemberToHome(HOME, `${HOME}-m${i}`, 'member', 'active', { completions60d: 50 - i });
    }

    await runCron();

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('restorable');
    expect(home['limits']['maxMembers']).toBe(3);
    expect(home['premiumTier']).toBe('grupo'); // sticky, para poder restaurar

    const dash = (await getDb().collection('homes').doc(HOME)
      .collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['tier']).toBe('free');
    expect(dash['premiumFlags']['maxMembers']).toBe(3);

    expect(await countByStatus(HOME, 'active')).toBe(3);
    expect(await countByStatus(HOME, 'frozen')).toBe(2);
  });
});

describe('restorePremiumState — recupera el tope del tier sticky', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  it('restorable con premiumTier grupo → maxMembers 10, descongela, dashboard grupo/10', async () => {
    const HOME = 'dgr-restore-grupo';
    await createHome(HOME, OWNER, {
      premiumStatus: 'restorable',
      premiumTier: 'grupo',
      restoreUntil: Timestamp.fromDate(new Date(Date.now() + 10 * 24 * 3600 * 1000)),
      limits: { maxMembers: 3, maxTasks: 50 },
    });
    await addMemberToHome(HOME, `${HOME}-a`, 'member', 'active');
    await addMemberToHome(HOME, `${HOME}-f1`, 'member', 'frozen');
    await addMemberToHome(HOME, `${HOME}-f2`, 'member', 'frozen');
    await createTask(HOME, 'tf', OWNER, { status: 'frozen' });

    await runRestore(makeCallableRequest(OWNER, { homeId: HOME }));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('active');
    expect(home['limits']['maxMembers']).toBe(10);
    expect(home['premiumTier']).toBe('grupo');

    const dash = (await getDb().collection('homes').doc(HOME)
      .collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['tier']).toBe('grupo');
    expect(dash['premiumFlags']['maxMembers']).toBe(10);

    expect(await countByStatus(HOME, 'frozen')).toBe(0);
    const task = (await getDb().collection('homes').doc(HOME).collection('tasks').doc('tf').get()).data()!;
    expect(task['status']).toBe('active');
  });

  it('restorable con premiumTier familia → maxMembers 5', async () => {
    const HOME = 'dgr-restore-familia';
    await createHome(HOME, OWNER, {
      premiumStatus: 'restorable',
      premiumTier: 'familia',
      restoreUntil: Timestamp.fromDate(new Date(Date.now() + 10 * 24 * 3600 * 1000)),
      limits: { maxMembers: 3, maxTasks: 50 },
    });
    await runRestore(makeCallableRequest(OWNER, { homeId: HOME }));
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(5);
    expect(home['premiumTier']).toBe('familia');
  });
});

describe('restorePremiumState — recupera tope incluyendo packs activos', () => {
  const FUTURE = () => Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z'));
  const PACK_ACTIVE = (chargeId: string) => ({ status: 'active', active: true, chargeId, endsAt: FUTURE() });

  beforeEach(() => {
    __setHomeTiersEnabledForTesting(true);
    __setMemberPacksEnabledForTesting(true);
  });
  afterAll(() => __setMemberPacksEnabledForTesting(undefined));

  it('Grupo sticky + packs +5/+10 activos → restaura a tope 25, dashboard memberPacks true', async () => {
    const HOME = 'dgr-restore-packs';
    await createHome(HOME, OWNER, {
      premiumStatus: 'restorable',
      premiumTier: 'grupo',
      restoreUntil: Timestamp.fromDate(new Date(Date.now() + 10 * 24 * 3600 * 1000)),
      limits: { maxMembers: 3, maxTasks: 50 },
      memberPacks: { plus5: PACK_ACTIVE('c5'), plus10: PACK_ACTIVE('c10') },
    });

    await runRestore(makeCallableRequest(OWNER, { homeId: HOME }));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(25);
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['maxMembers']).toBe(25);
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: true, plus10: true });
  });

  it('flag de packs OFF → restaura solo al tope del tier (Grupo 10), packs dormidos', async () => {
    __setMemberPacksEnabledForTesting(false);
    const HOME = 'dgr-restore-packs-off';
    await createHome(HOME, OWNER, {
      premiumStatus: 'restorable',
      premiumTier: 'grupo',
      restoreUntil: Timestamp.fromDate(new Date(Date.now() + 10 * 24 * 3600 * 1000)),
      limits: { maxMembers: 3, maxTasks: 50 },
      memberPacks: { plus5: PACK_ACTIVE('c5'), plus10: PACK_ACTIVE('c10') },
    });
    await runRestore(makeCallableRequest(OWNER, { homeId: HOME }));
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(10);
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: false, plus10: false });
  });
});
