// functions/test/integration/member_packs.test.ts
//
// Eje de PACKS DE MIEMBRO (aditivo y reversible sobre un hogar Grupo):
// applyPackEntitlement / reconcileVerifiedPack / revokePack.
//
// Cubre: tope efectivo 10/15/20/25, congelación de excedentes al perder un pack
// (reusando autoSelectForDowngrade), idempotencia, renovación (no acorta), guard
// por chargeId, separación de ejes (NO toca lifetimeUnlockedHomeSlots), flag off
// (pack dormido), y pack sobre tier no-Grupo (dormido).
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, createTask, getDb,
} from './helpers/setup';
import {
  applyPackEntitlement,
  reconcileVerifiedPack,
  revokePack,
} from '../../src/entitlement/pack_entitlement';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;
const FUTURE = new Date('2027-06-01T00:00:00.000Z');

/** Crea un hogar premium Grupo con `extraMembers` miembros además del owner. */
async function seedGrupoHome(
  homeId: string, ownerUid: string, extraMembers: number,
  packs: Record<string, unknown> = {}, maxMembers = 10,
): Promise<void> {
  await createHome(homeId, ownerUid, {
    premiumStatus: 'active',
    premiumTier: 'grupo',
    premiumPlan: 'monthly',
    premiumEndsAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00.000Z')),
    currentPayerUid: ownerUid,
    limits: { maxMembers, maxTasks: 50 },
    ...(Object.keys(packs).length ? { memberPacks: packs } : {}),
  });
  for (let i = 0; i < extraMembers; i++) {
    // completions60d decreciente → el de mayor índice se congela primero.
    await addMemberToHome(homeId, `${homeId}-m${i}`, 'member', 'active', {
      completions60d: 1000 - i,
    });
  }
}

async function countByStatus(homeId: string, status: string): Promise<number> {
  const snap = await getDb().collection('homes').doc(homeId)
    .collection('members').where('status', '==', status).get();
  return snap.size;
}

async function getHome(homeId: string): Promise<admin.firestore.DocumentData> {
  return (await getDb().collection('homes').doc(homeId).get()).data()!;
}

function verifiedPack(productId: string, over: Partial<VerifiedReceipt> = {}): VerifiedReceipt {
  return {
    status: 'active',
    plan: productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: FUTURE,
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: `charge-${productId}`,
    productId,
    ...over,
  };
}

const OWNER = 'owner-packs';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
});

beforeEach(() => {
  __setHomeTiersEnabledForTesting(true);
  __setMemberPacksEnabledForTesting(true);
});

afterAll(() => {
  __setHomeTiersEnabledForTesting(undefined);
  __setMemberPacksEnabledForTesting(undefined);
});

describe('applyPackEntitlement — compra/activación de pack sobre Grupo', () => {
  it('Pack +5 sobre Grupo(10): tope 15, entrada registrada, dashboard 15', async () => {
    const HOME = 'pack-buy5';
    await seedGrupoHome(HOME, OWNER, 2);
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus5', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack5_monthly',
      platform: 'android', chargeId: 'c-buy5', source: 'purchase',
    });

    expect(res.applied).toBe(true);
    expect(res.maxMembers).toBe(15);
    const home = await getHome(HOME);
    expect(home['limits']['maxMembers']).toBe(15);
    expect(home['memberPacks']['plus5']['active']).toBe(true);
    expect(home['memberPacks']['plus5']['status']).toBe('active');
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['maxMembers']).toBe(15);
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: true, plus10: false });
  });

  it('Solo Pack +10 sobre Grupo: tope 20', async () => {
    const HOME = 'pack-buy10';
    await seedGrupoHome(HOME, OWNER, 1);
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus10', status: 'active', cycle: 'annual',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack10_annual',
      platform: 'android', chargeId: 'c-buy10', source: 'purchase',
    });
    expect(res.maxMembers).toBe(20);
    expect((await getHome(HOME))['limits']['maxMembers']).toBe(20);
  });

  it('Pack +5 y Pack +10 → tope 25 (cap absoluto)', async () => {
    const HOME = 'pack-buyboth';
    await seedGrupoHome(HOME, OWNER, 1, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(FUTURE) },
    }, 15);
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus10', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack10_monthly',
      platform: 'android', chargeId: 'c10', source: 'purchase',
    });
    expect(res.maxMembers).toBe(25);
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(true);
    expect(home['memberPacks']['plus10']['active']).toBe(true);
  });

  it('compra no congela (el tope sube): sin congelados', async () => {
    const HOME = 'pack-nofreeze';
    await seedGrupoHome(HOME, OWNER, 9); // 10 activos (tope grupo)
    await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus5', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack5_monthly',
      platform: 'android', chargeId: 'c', source: 'purchase',
    });
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
    expect(await countByStatus(HOME, 'active')).toBe(10);
  });

  it('renovación (laterTimestamp): no acorta endsAt y mantiene plazas', async () => {
    const HOME = 'pack-renew';
    const later = new Date('2028-01-01T00:00:00.000Z');
    await seedGrupoHome(HOME, OWNER, 11, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(later) },
    }, 15); // 12 activos, cap 15
    // Notificación de renovación con endsAt ANTERIOR → no debe acortar.
    await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus5', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack5_monthly',
      platform: 'android', chargeId: 'c5', source: 'store_notification',
    });
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['endsAt'].toMillis()).toBe(later.getTime());
    expect(home['limits']['maxMembers']).toBe(15);
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
  });
});

describe('applyPackEntitlement/revokePack — pérdida de pack congela excedentes', () => {
  it('expiración de +10 desde 25→15 congela exactamente los excedentes, owner intacto', async () => {
    const HOME = 'pack-expire10';
    // 21 activos (owner + 20), ambos packs activos, cap 25.
    await seedGrupoHome(HOME, OWNER, 20, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(FUTURE) },
      plus10: { status: 'active', active: true, chargeId: 'c10', endsAt: Timestamp.fromDate(FUTURE) },
    }, 25);
    await createTask(HOME, 't1', OWNER);

    // Notificación: +10 expira (status expired) → cap 15.
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus10', status: 'expired', cycle: 'monthly',
      endsAt: new Date('2026-01-01T00:00:00.000Z'), autoRenewEnabled: false,
      productId: 'toka_pack10_monthly', platform: 'android', chargeId: 'c10',
      source: 'store_notification',
    });

    expect(res.maxMembers).toBe(15);
    expect(res.frozen).toBe(6); // 21 → 15
    expect(await countByStatus(HOME, 'active')).toBe(15);
    expect(await countByStatus(HOME, 'frozen')).toBe(6);
    const owner = (await getDb().collection('homes').doc(HOME).collection('members').doc(OWNER).get()).data()!;
    expect(owner['status']).toBe('active');
    // Tareas intactas (sigue premium).
    const activeTasks = await getDb().collection('homes').doc(HOME).collection('tasks').where('status', '==', 'active').get();
    expect(activeTasks.size).toBe(1);
  });

  it('revokePack (refund) de +5 desde 15→10 congela 2 y NO toca lifetimeUnlockedHomeSlots', async () => {
    const HOME = 'pack-revoke5';
    await createUser(`${HOME}-payer`, { lifetimeUnlockedHomeSlots: 2, baseHomeSlots: 2, homeSlotCap: 4 });
    await seedGrupoHome(HOME, OWNER, 11, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(FUTURE) },
    }, 15); // 12 activos, cap 15
    await getDb().collection('homes').doc(HOME).update({ currentPayerUid: `${HOME}-payer` });

    const res = await revokePack(getDb(), {
      homeId: HOME, kind: 'plus5', chargeId: 'c5', reason: 'google_voided',
    });

    expect(res.revoked).toBe(true);
    expect(res.maxMembers).toBe(10);
    expect(res.frozen).toBe(2); // 12 → 10
    expect(await countByStatus(HOME, 'active')).toBe(10);
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(false);
    expect(home['memberPacks']['plus5']['status']).toBe('refunded');
    // EJE SEPARADO: el ledger de slots permanentes del pagador NO se toca.
    const payer = (await getDb().collection('users').doc(`${HOME}-payer`).get()).data()!;
    expect(payer['lifetimeUnlockedHomeSlots']).toBe(2);
    expect(payer['homeSlotCap']).toBe(4);
  });

  it('mantiene a los miembros MÁS activos (mayor completions60d)', async () => {
    const HOME = 'pack-keep-active';
    await seedGrupoHome(HOME, OWNER, 14, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(FUTURE) },
    }, 15); // 15 activos
    await revokePack(getDb(), { homeId: HOME, kind: 'plus5', chargeId: 'c5', reason: 'expired' });
    // cap 10 → owner + 9 más activos (m0..m8). m9..m13 congelados.
    const m0 = (await getDb().collection('homes').doc(HOME).collection('members').doc(`${HOME}-m0`).get()).data()!;
    const m13 = (await getDb().collection('homes').doc(HOME).collection('members').doc(`${HOME}-m13`).get()).data()!;
    expect(m0['status']).toBe('active');
    expect(m13['status']).toBe('frozen');
  });
});

describe('applyPackEntitlement/revokePack — idempotencia, guard, flag y tier', () => {
  it('reprocesar la misma expiración no congela de más', async () => {
    const HOME = 'pack-idem';
    await seedGrupoHome(HOME, OWNER, 13, {
      plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(FUTURE) },
    }, 15); // 14 activos
    const input = {
      homeId: HOME, kind: 'plus5' as const, status: 'expired', cycle: 'monthly' as const,
      endsAt: new Date('2026-01-01T00:00:00.000Z'), autoRenewEnabled: false,
      productId: 'toka_pack5_monthly', platform: 'android' as const, chargeId: 'c5',
      source: 'store_notification',
    };
    await applyPackEntitlement(getDb(), input);
    await applyPackEntitlement(getDb(), input);
    expect(await countByStatus(HOME, 'active')).toBe(10);
    expect(await countByStatus(HOME, 'frozen')).toBe(4);
  });

  it('revokePack con chargeId superado → no revoca el pack más reciente', async () => {
    const HOME = 'pack-superseded';
    await seedGrupoHome(HOME, OWNER, 11, {
      plus5: { status: 'active', active: true, chargeId: 'c-new', endsAt: Timestamp.fromDate(FUTURE) },
    }, 15);
    const res = await revokePack(getDb(), { homeId: HOME, kind: 'plus5', chargeId: 'c-old', reason: 'refund' });
    expect(res.revoked).toBe(false);
    expect(res.reason).toBe('charge-superseded');
    expect((await getHome(HOME))['memberPacks']['plus5']['active']).toBe(true);
  });

  it('flag de packs OFF → registra la entrada pero el tope queda en 10 (dormido), no congela', async () => {
    __setMemberPacksEnabledForTesting(false);
    const HOME = 'pack-flagoff';
    await seedGrupoHome(HOME, OWNER, 9); // 10 activos
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus5', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack5_monthly',
      platform: 'android', chargeId: 'c', source: 'purchase',
    });
    expect(res.maxMembers).toBe(10);
    const home = await getHome(HOME);
    expect(home['limits']['maxMembers']).toBe(10);
    expect(home['memberPacks']['plus5']['active']).toBe(true); // entrada registrada (verdad de la store)
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
  });

  it('pack sobre hogar Familia (no Grupo) → dormido (tope 5), entrada registrada', async () => {
    const HOME = 'pack-familia';
    await createHome(HOME, OWNER, {
      premiumStatus: 'active', premiumTier: 'familia', premiumPlan: 'monthly',
      currentPayerUid: OWNER, limits: { maxMembers: 5, maxTasks: 50 },
    });
    const res = await applyPackEntitlement(getDb(), {
      homeId: HOME, kind: 'plus10', status: 'active', cycle: 'monthly',
      endsAt: FUTURE, autoRenewEnabled: true, productId: 'toka_pack10_monthly',
      platform: 'android', chargeId: 'c', source: 'store_notification',
    });
    expect(res.maxMembers).toBe(5);
    expect((await getHome(HOME))['memberPacks']['plus10']['active']).toBe(true);
  });

  it('home inexistente → no-op', async () => {
    const res = await reconcileVerifiedPack(
      getDb(), { homeId: 'no-such-home', uid: OWNER, platform: 'android' },
      verifiedPack('toka_pack5_monthly'),
    );
    expect(res.applied).toBe(false);
    expect(res.reason).toBe('home-not-found');
  });

  it('reconcileVerifiedPack deriva kind del productId y aplica', async () => {
    const HOME = 'pack-reconcile';
    await seedGrupoHome(HOME, OWNER, 2);
    const res = await reconcileVerifiedPack(
      getDb(), { homeId: HOME, uid: OWNER, platform: 'android' },
      verifiedPack('toka_pack10_monthly'),
    );
    expect(res.maxMembers).toBe(20);
    expect((await getHome(HOME))['memberPacks']['plus10']['active']).toBe(true);
  });
});
