// functions/test/integration/sync_entitlement_packs.test.ts
//
// Ruta "pack de miembro" de la callable syncEntitlement: un SKU de pack amplía el
// tope de un hogar GRUPO (eje aditivo) escribiendo home.memberPacks.{kind} y el
// índice de compra con kind='pack'. Valida el requisito de Grupo (rechazo
// server-side sobre Pareja/Familia/Free) y que el flag OFF registra el pack
// dormido sin rechazar.

import {
  cleanAll, createUser, createHome, addMemberToHome, getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';
import {
  __setReceiptVerifiersForTesting,
  type ReceiptVerifiers,
} from '../../src/entitlement/sync_entitlement_helpers';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const wrapped = (req: any): Promise<any> => (syncEntitlement as any).run(req);

const OWNER = 'pack-sync-owner';

function packReceipt(productId: string, token: string): string {
  return JSON.stringify({
    productId, purchaseToken: token, transactionId: 'TX.' + token, source: 'google_play',
  });
}

function verifiedPack(productId: string, token: string, over: Partial<VerifiedReceipt> = {}): VerifiedReceipt {
  return {
    status: 'active',
    plan: productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: new Date(Date.now() + 31 * 24 * 3600 * 1000),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: token,
    productId,
    ...over,
  };
}

function installVerifier(impl: () => Promise<VerifiedReceipt>) {
  const verifiers: ReceiptVerifiers = { verifyGooglePlay: impl };
  __setReceiptVerifiersForTesting(verifiers);
}

/** Crea un hogar premium en el tier dado con el owner como miembro activo. */
async function seedHome(homeId: string, tier: string | null, premiumStatus = 'active', maxMembers = 10): Promise<void> {
  await createHome(homeId, OWNER, {
    premiumStatus, premiumTier: tier, premiumPlan: 'monthly',
    currentPayerUid: OWNER, limits: { maxMembers, maxTasks: 50 },
  });
}

let prevFunctionsEmulator: string | undefined;
beforeAll(async () => {
  prevFunctionsEmulator = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = 'true';
  await cleanAll();
  await createUser(OWNER);
});

beforeEach(() => {
  __setHomeTiersEnabledForTesting(true);
  __setMemberPacksEnabledForTesting(true);
});

afterAll(() => {
  __setReceiptVerifiersForTesting(undefined);
  __setHomeTiersEnabledForTesting(undefined);
  __setMemberPacksEnabledForTesting(undefined);
  if (prevFunctionsEmulator === undefined) delete process.env.FUNCTIONS_EMULATOR;
  else process.env.FUNCTIONS_EMULATOR = prevFunctionsEmulator;
});

describe('syncEntitlement — compra de pack sobre Grupo', () => {
  it('SKU pack +5 sobre Grupo: tope 15, memberPacks.plus5 activo, purchaseIndex kind="pack"', async () => {
    const HOME = 'pack-sync-grupo';
    await seedHome(HOME, 'grupo');
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-p5'));

    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-p5'), platform: 'android',
    }));

    expect(result.success).toBe(true);
    expect(result.pack).toEqual({ kind: 'plus5', active: true, maxMembers: 15 });

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(15);
    expect(home['memberPacks']['plus5']['active']).toBe(true);
    // El estado premium/tier del hogar NO cambia (eje aditivo).
    expect(home['premiumTier']).toBe('grupo');
    expect(home['premiumStatus']).toBe('active');

    const idx = (await getDb().collection('purchaseIndex').doc('tok-p5').get()).data()!;
    expect(idx['kind']).toBe('pack');
    expect(idx['homeId']).toBe(HOME);
    expect(idx['productId']).toBe('toka_pack5_monthly');
  });

  it('separación de ejes: comprar pack NO toca lifetimeUnlockedHomeSlots del comprador', async () => {
    const HOME = 'pack-sync-axis';
    await createUser('axis-buyer', { lifetimeUnlockedHomeSlots: 1, baseHomeSlots: 2, homeSlotCap: 3 });
    await seedHome(HOME, 'grupo');
    await addMemberToHome(HOME, 'axis-buyer', 'admin', 'active');
    installVerifier(async () => verifiedPack('toka_pack10_monthly', 'tok-axis'));

    await wrapped(makeCallableRequest('axis-buyer', {
      homeId: HOME, receiptData: packReceipt('toka_pack10_monthly', 'tok-axis'), platform: 'android',
    }));

    const user = (await getDb().collection('users').doc('axis-buyer').get()).data()!;
    expect(user['lifetimeUnlockedHomeSlots']).toBe(1); // intacto
    expect(user['homeSlotCap']).toBe(3);
  });
});

describe('syncEntitlement — requiere Grupo (rechazo server-side)', () => {
  it('pack sobre Familia → failed-precondition pack-requires-grupo', async () => {
    const HOME = 'pack-sync-familia';
    await seedHome(HOME, 'familia', 'active', 5);
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-fam'));
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-fam'), platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    // No se registró el pack.
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['memberPacks']).toBeUndefined();
  });

  it('pack sobre hogar Free/no-premium → rechazo', async () => {
    const HOME = 'pack-sync-free';
    await seedHome(HOME, null, 'free', 3);
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-free'));
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-free'), platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('flag de tiers OFF (binario) → rechazo (no existe Grupo)', async () => {
    __setHomeTiersEnabledForTesting(false);
    const HOME = 'pack-sync-binary';
    await seedHome(HOME, 'grupo', 'active', 10);
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-bin'));
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-bin'), platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('comprador no es miembro activo → permission-denied', async () => {
    const HOME = 'pack-sync-nonmember';
    await createUser('outsider');
    await seedHome(HOME, 'grupo');
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-out'));
    await expect(
      wrapped(makeCallableRequest('outsider', {
        homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-out'), platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('pack sin homeId → invalid-argument', async () => {
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-nohome'));
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        receiptData: packReceipt('toka_pack5_monthly', 'tok-nohome'), platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('syncEntitlement — re-sync del TIER preserva los packs', () => {
  it('re-sync del recibo de Grupo en un hogar con packs NO baja el tope a 10', async () => {
    const HOME = 'pack-sync-tier-resync';
    const { Timestamp } = await import('firebase-admin/firestore');
    await createHome(HOME, OWNER, {
      premiumStatus: 'active', premiumTier: 'grupo', premiumPlan: 'monthly',
      currentPayerUid: OWNER, limits: { maxMembers: 25, maxTasks: 50 },
      memberPacks: {
        plus5: { status: 'active', active: true, chargeId: 'c5', endsAt: Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z')) },
        plus10: { status: 'active', active: true, chargeId: 'c10', endsAt: Timestamp.fromDate(new Date('2027-06-01T00:00:00.000Z')) },
      },
    });
    installVerifier(async () => ({
      status: 'active', plan: 'monthly', endsAt: new Date(Date.now() + 31 * 24 * 3600 * 1000),
      autoRenewEnabled: true, storeVerified: true, chargeId: 'grupo-resync', productId: 'toka_grupo_monthly',
    }));

    await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: packReceipt('toka_grupo_monthly', 'grupo-resync'), platform: 'android',
    }));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(25); // packs preservados
    const dash = (await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['maxMembers']).toBe(25);
    expect(dash['premiumFlags']['memberPacks']).toEqual({ plus5: true, plus10: true });
  });
});

describe('syncEntitlement — flag de packs OFF (pack dormido, no rechazo)', () => {
  it('registra el pack pero el tope queda en 10 (Grupo) sin rechazar', async () => {
    __setMemberPacksEnabledForTesting(false);
    const HOME = 'pack-sync-flagoff';
    await seedHome(HOME, 'grupo');
    installVerifier(async () => verifiedPack('toka_pack5_monthly', 'tok-off'));

    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: packReceipt('toka_pack5_monthly', 'tok-off'), platform: 'android',
    }));
    expect(result.success).toBe(true);
    expect(result.pack.maxMembers).toBe(10); // dormido

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(10);
    expect(home['memberPacks']['plus5']['active']).toBe(true); // entrada registrada
  });
});
