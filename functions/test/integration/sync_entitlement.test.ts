// functions/test/integration/sync_entitlement.test.ts
import {
  cleanAll, createUser, createHome, addMemberToHome,
  getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';
import {
  __setReceiptVerifiersForTesting,
  type ReceiptVerifiers,
} from '../../src/entitlement/sync_entitlement_helpers';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const wrapped = (req: any): Promise<any> => (syncEntitlement as any).run(req);

const HOME = 'home-sync';
const OWNER = 'owner-sync';
const MEMBER = 'member-sync';

// El cliente ahora envía SOLO datos firmables por la store (productId,
// purchaseToken, transactionId, source); el backend deriva el estado del recibo
// verificado server-to-store (aquí mockeado).
const androidReceipt = JSON.stringify({
  productId: 'toka_premium_monthly',
  purchaseToken: 'gp-token-sync-1',
  transactionId: 'GPA.SYNC.1',
  source: 'google_play',
});

function verified(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active',
    plan: 'monthly',
    endsAt: new Date('2027-06-01T00:00:00.000Z'),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: 'gp-token-sync-1',
    productId: 'toka_premium_monthly',
    ...over,
  };
}

function installVerifier(impl: () => Promise<VerifiedReceipt>) {
  const verifiers: ReceiptVerifiers = { verifyGooglePlay: impl };
  __setReceiptVerifiersForTesting(verifiers);
}

let prevFunctionsEmulator: string | undefined;
beforeAll(async () => {
  prevFunctionsEmulator = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = 'true';
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
});

afterAll(() => {
  __setReceiptVerifiersForTesting(undefined);
  if (prevFunctionsEmulator === undefined) delete process.env.FUNCTIONS_EMULATOR;
  else process.env.FUNCTIONS_EMULATOR = prevFunctionsEmulator;
});

describe('syncEntitlement — happy path (recibo verificado)', () => {
  beforeEach(() => installVerifier(async () => verified({})));

  it('recibo válido verificado activa premium en el hogar', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));

    expect(result.success).toBe(true);
    expect(result.premiumStatus).toBe('active');

    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('active');
    expect(homeDoc.data()!['currentPayerUid']).toBe(OWNER);
  });

  it('crea doc en subscriptions/history/charges con chargeId derivado server-side', async () => {
    // chargeId = purchaseToken verificado, no el purchaseID del cliente.
    const chargeDoc = await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('gp-token-sync-1')
      .get();
    expect(chargeDoc.exists).toBe(true);
    expect(chargeDoc.data()!['status']).toBe('active');
    expect(chargeDoc.data()!['storeVerified']).toBe(true);
  });

  it('actualiza premiumFlags en dashboard', async () => {
    const dashDoc = await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dashDoc.data()?.['premiumFlags']?.['isPremium']).toBe(true);
    expect(dashDoc.data()?.['premiumFlags']?.['showAds']).toBe(false);
  });

  it('marca billingState=currentPayer en la membership del pagador', async () => {
    const membership = await getDb()
      .collection('users').doc(OWNER)
      .collection('memberships').doc(HOME).get();
    expect(membership.data()?.['billingState']).toBe('currentPayer');
  });

  it('recibo verificado expirado deja premiumStatus = expired', async () => {
    installVerifier(async () => verified({
      status: 'expired',
      chargeId: 'gp-token-sync-2',
      endsAt: new Date('2020-01-01T00:00:00.000Z'),
    }));
    const receipt2 = JSON.stringify({
      productId: 'toka_premium_monthly',
      purchaseToken: 'gp-token-sync-2',
      transactionId: 'GPA.SYNC.2',
      source: 'google_play',
    });
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: receipt2, platform: 'android',
    }));
    expect(result.premiumStatus).toBe('expired');
    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('expired');
  });
});

describe('syncEntitlement — errores', () => {
  beforeEach(() => installVerifier(async () => verified({})));

  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, receiptData: androidReceipt, platform: 'android' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('usuario no miembro del hogar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest('outsider-sync', {
        homeId: HOME, receiptData: androidReceipt, platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('campos requeridos vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: '', receiptData: '', platform: 'android',
      }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
