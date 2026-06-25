// functions/test/integration/reconcile_tiers.test.ts
//
// Downgrade ENTRE TIERS vía reconciliación con store (RTDN/ASN): al bajar de
// tier se congelan los miembros que exceden el nuevo tope; subir de tier no
// congela; las tareas no se tocan (sigue premium).
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, createTask, getDb,
} from './helpers/setup';
import { reconcileVerifiedEntitlement, type PurchaseRef } from '../../src/entitlement/reconcile_entitlement';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;

function verified(productId: string, over: Partial<VerifiedReceipt> = {}): VerifiedReceipt {
  return {
    status: 'active',
    plan: productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: new Date('2027-06-01T00:00:00.000Z'),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: `charge-${productId}`,
    productId,
    ...over,
  };
}

/** Crea un hogar premium en `tier` con `extraMembers` miembros además del owner. */
async function seedPremiumHome(
  homeId: string, ownerUid: string, tier: string, maxMembers: number, extraMembers: number,
): Promise<void> {
  await createHome(homeId, ownerUid, {
    premiumStatus: 'active',
    premiumTier: tier,
    premiumPlan: 'monthly',
    premiumEndsAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00.000Z')),
    currentPayerUid: ownerUid,
    limits: { maxMembers, maxTasks: 50 },
  });
  for (let i = 0; i < extraMembers; i++) {
    // completions60d decreciente → el de mayor índice se congela primero.
    await addMemberToHome(homeId, `${homeId}-m${i}`, 'member', 'active', {
      completions60d: 100 - i,
    });
  }
}

async function countByStatus(homeId: string, status: string): Promise<number> {
  const snap = await getDb().collection('homes').doc(homeId)
    .collection('members').where('status', '==', status).get();
  return snap.size;
}

const OWNER = 'owner-rec-tiers';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
});

afterAll(() => __setHomeTiersEnabledForTesting(undefined));

describe('reconcileVerifiedEntitlement — downgrade entre tiers congela excedentes', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  it('Grupo(10, 7 activos) → Familia(5): congela exactamente 2, owner intacto', async () => {
    const HOME = 'rec-grupo-familia';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 6); // owner + 6 = 7 activos
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_familia_monthly' };

    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumTier']).toBe('familia');
    expect(home['limits']['maxMembers']).toBe(5);
    expect(await countByStatus(HOME, 'active')).toBe(5);
    expect(await countByStatus(HOME, 'frozen')).toBe(2);
    const owner = (await getDb().collection('homes').doc(HOME).collection('members').doc(OWNER).get()).data()!;
    expect(owner['status']).toBe('active');
  });

  it('Grupo(10, 5 activos) → Pareja(2): congela 3', async () => {
    const HOME = 'rec-grupo-pareja';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 4); // owner + 4 = 5
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_pareja_monthly' };

    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_pareja_monthly'));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumTier']).toBe('pareja');
    expect(home['limits']['maxMembers']).toBe(2);
    expect(await countByStatus(HOME, 'active')).toBe(2);
    expect(await countByStatus(HOME, 'frozen')).toBe(3);
  });

  it('Familia(5, 4 activos) → Pareja(2): congela 2', async () => {
    const HOME = 'rec-familia-pareja';
    await seedPremiumHome(HOME, OWNER, 'familia', 5, 3); // owner + 3 = 4
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_pareja_monthly' };

    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_pareja_monthly'));

    expect(await countByStatus(HOME, 'active')).toBe(2);
    expect(await countByStatus(HOME, 'frozen')).toBe(2);
  });

  it('mantiene a los miembros MÁS activos (mayor completions60d)', async () => {
    const HOME = 'rec-keep-active';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 4); // m0..m3, completions 100..97
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_pareja_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_pareja_monthly'));

    // Pareja=2 → owner + m0 (el más activo). m1,m2,m3 congelados.
    const m0 = (await getDb().collection('homes').doc(HOME).collection('members').doc(`${HOME}-m0`).get()).data()!;
    const m3 = (await getDb().collection('homes').doc(HOME).collection('members').doc(`${HOME}-m3`).get()).data()!;
    expect(m0['status']).toBe('active');
    expect(m3['status']).toBe('frozen');
  });

  it('NO congela tareas en un downgrade entre tiers (sigue premium)', async () => {
    const HOME = 'rec-tasks-intact';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 6);
    for (let i = 0; i < 8; i++) await createTask(HOME, `t${i}`, OWNER);
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_familia_monthly' };

    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));

    const activeTasks = await getDb().collection('homes').doc(HOME)
      .collection('tasks').where('status', '==', 'active').get();
    expect(activeTasks.size).toBe(8);
  });

  it('actualiza el dashboard (tier + maxMembers efectivos)', async () => {
    const HOME = 'rec-dash';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 4);
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_familia_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['tier']).toBe('familia');
    expect(dash['premiumFlags']['maxMembers']).toBe(5);
  });
});

describe('reconcileVerifiedEntitlement — subida de tier NO congela', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  it('Pareja(2) → Grupo(10): sin congelados, maxMembers 10', async () => {
    const HOME = 'rec-upgrade';
    await seedPremiumHome(HOME, OWNER, 'pareja', 2, 1); // owner + 1 = 2
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_grupo_monthly' };

    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_grupo_monthly'));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumTier']).toBe('grupo');
    expect(home['limits']['maxMembers']).toBe(10);
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
    expect(await countByStatus(HOME, 'active')).toBe(2);
  });
});

describe('reconcileVerifiedEntitlement — idempotencia y flag OFF', () => {
  it('reprocesar el mismo downgrade no congela de más', async () => {
    __setHomeTiersEnabledForTesting(true);
    const HOME = 'rec-idem';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 6); // 7 activos
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_familia_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));
    // Tras el 1er downgrade: 5 activos / 2 congelados. El 2º es no-op.
    expect(await countByStatus(HOME, 'active')).toBe(5);
    expect(await countByStatus(HOME, 'frozen')).toBe(2);
  });

  it('flag OFF → binario 10, no congela aunque el SKU sea Pareja', async () => {
    __setHomeTiersEnabledForTesting(false);
    const HOME = 'rec-flagoff';
    await seedPremiumHome(HOME, OWNER, 'grupo', 10, 6); // 7 activos
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_pareja_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_pareja_monthly'));
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(10);
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
  });
});

describe('reconcileVerifiedEntitlement — renovación de TIER con packs activos', () => {
  beforeEach(() => {
    __setHomeTiersEnabledForTesting(true);
    __setMemberPacksEnabledForTesting(true);
  });
  afterAll(() => __setMemberPacksEnabledForTesting(undefined));

  it('renovación de Grupo con +5 y +10 activos PRESERVA el tope 25 (no congela)', async () => {
    const HOME = 'rec-grupo-packs';
    await createHome(HOME, OWNER, {
      premiumStatus: 'active', premiumTier: 'grupo', premiumPlan: 'monthly',
      premiumEndsAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00.000Z')),
      currentPayerUid: OWNER, limits: { maxMembers: 25, maxTasks: 50 },
      memberPacks: {
        plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z')) },
        plus10: { status: 'active', active: true, chargeId: 'c10', endsAt: Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z')) },
      },
    });
    for (let i = 0; i < 14; i++) await addMemberToHome(HOME, `${HOME}-m${i}`, 'member', 'active', { completions60d: 100 - i });
    // 15 activos, cap 25. Renovación del TIER Grupo (RTDN).
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_grupo_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_grupo_monthly'));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(25); // packs preservados, NO baja a 10
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
    expect(await countByStatus(HOME, 'active')).toBe(15);
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: true, plus10: true });
  });

  it('downgrade Grupo→Familia con packs activos → tope 5 (packs dormidos), congela', async () => {
    const HOME = 'rec-grupo-familia-packs';
    await createHome(HOME, OWNER, {
      premiumStatus: 'active', premiumTier: 'grupo', premiumPlan: 'monthly',
      premiumEndsAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00.000Z')),
      currentPayerUid: OWNER, limits: { maxMembers: 25, maxTasks: 50 },
      memberPacks: {
        plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z')) },
      },
    });
    for (let i = 0; i < 9; i++) await addMemberToHome(HOME, `${HOME}-m${i}`, 'member', 'active', { completions60d: 100 - i });
    // 10 activos, cap 15. Cambio de plan a Familia.
    const ref: PurchaseRef = { homeId: HOME, uid: OWNER, platform: 'android', productId: 'toka_familia_monthly' };
    await reconcileVerifiedEntitlement(getDb(), ref, verified('toka_familia_monthly'));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(5); // packs dormidos (no es Grupo)
    expect(await countByStatus(HOME, 'active')).toBe(5);
    expect(await countByStatus(HOME, 'frozen')).toBe(5);
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: false, plus10: false });
  });
});
