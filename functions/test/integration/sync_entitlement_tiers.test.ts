// functions/test/integration/sync_entitlement_tiers.test.ts
//
// Persistencia del TIER y del tope efectivo en syncEntitlement, gateada por el
// flag home_tiers_enabled (inyectado en tests).
import {
  cleanAll, createUser, createHome, getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';
import {
  __setReceiptVerifiersForTesting,
  type ReceiptVerifiers,
} from '../../src/entitlement/sync_entitlement_helpers';
import { __setHomeTiersEnabledForTesting } from '../../src/shared/feature_flags';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const wrapped = (req: any): Promise<any> => (syncEntitlement as any).run(req);
const OWNER = 'owner-tiers';

function installVerifierFor(productId: string, chargeId: string) {
  const impl = async (): Promise<VerifiedReceipt> => ({
    status: 'active',
    plan: productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: new Date('2027-06-01T00:00:00.000Z'),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId,
    productId,
  });
  const verifiers: ReceiptVerifiers = { verifyGooglePlay: impl };
  __setReceiptVerifiersForTesting(verifiers);
}

async function syncProduct(homeId: string, productId: string, token: string) {
  installVerifierFor(productId, token);
  const receipt = JSON.stringify({
    productId, purchaseToken: token, transactionId: `TX.${token}`, source: 'google_play',
  });
  return wrapped(makeCallableRequest(OWNER, {
    homeId, receiptData: receipt, platform: 'android',
  }));
}

let prevFunctionsEmulator: string | undefined;
beforeAll(async () => {
  prevFunctionsEmulator = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = 'true';
  await cleanAll();
  await createUser(OWNER);
});

afterAll(() => {
  __setReceiptVerifiersForTesting(undefined);
  __setHomeTiersEnabledForTesting(undefined);
  if (prevFunctionsEmulator === undefined) delete process.env.FUNCTIONS_EMULATOR;
  else process.env.FUNCTIONS_EMULATOR = prevFunctionsEmulator;
});

describe('syncEntitlement — flag ON: persiste tier + tope por SKU', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(true));

  const cases: Array<[string, string, number]> = [
    ['toka_pareja_monthly', 'pareja', 2],
    ['toka_pareja_annual', 'pareja', 2],
    ['toka_familia_monthly', 'familia', 5],
    ['toka_familia_annual', 'familia', 5],
    ['toka_grupo_monthly', 'grupo', 10],
    ['toka_grupo_annual', 'grupo', 10],
  ];

  it.each(cases)('%s → tier %s, maxMembers %d (home + dashboard)', async (productId, tier, max) => {
    const homeId = `home-${productId}`;
    await createHome(homeId, OWNER);
    await syncProduct(homeId, productId, `tok-${productId}`);

    const home = (await getDb().collection('homes').doc(homeId).get()).data()!;
    expect(home['premiumTier']).toBe(tier);
    expect(home['limits']['maxMembers']).toBe(max);

    const dash = (await getDb().collection('homes').doc(homeId)
      .collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['tier']).toBe(tier);
    expect(dash['premiumFlags']['maxMembers']).toBe(max);
    expect(dash['premiumFlags']['isPremium']).toBe(true);
  });

  it('SKU legacy toka_premium_monthly → tier grupo (10)', async () => {
    const homeId = 'home-legacy';
    await createHome(homeId, OWNER);
    await syncProduct(homeId, 'toka_premium_monthly', 'tok-legacy');
    const home = (await getDb().collection('homes').doc(homeId).get()).data()!;
    expect(home['premiumTier']).toBe('grupo');
    expect(home['limits']['maxMembers']).toBe(10);
  });

  it('producto premium DESCONOCIDO → fail-safe Free (3), sigue premium', async () => {
    const homeId = 'home-unknown';
    await createHome(homeId, OWNER);
    const res = await syncProduct(homeId, 'toka_misterioso_monthly', 'tok-unknown');
    expect(res.premiumStatus).toBe('active');
    const home = (await getDb().collection('homes').doc(homeId).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(3);
    expect(home['premiumTier']).toBe('free');
  });
});

describe('syncEntitlement — flag OFF: comportamiento binario (10)', () => {
  beforeEach(() => __setHomeTiersEnabledForTesting(false));

  it('cualquier SKU premium → maxMembers 10, tier null', async () => {
    const homeId = 'home-flagoff';
    await createHome(homeId, OWNER);
    await syncProduct(homeId, 'toka_pareja_monthly', 'tok-flagoff');
    const home = (await getDb().collection('homes').doc(homeId).get()).data()!;
    expect(home['limits']['maxMembers']).toBe(10);
    expect(home['premiumTier'] ?? null).toBeNull();

    const dash = (await getDb().collection('homes').doc(homeId)
      .collection('views').doc('dashboard').get()).data()!;
    expect(dash['premiumFlags']['maxMembers']).toBe(10);
    expect(dash['premiumFlags']['tier'] ?? null).toBeNull();
  });
});
