// functions/test/integration/sync_entitlement.test.ts
import {
  cleanAll, createUser, createHome, addMemberToHome,
  getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';

const wrapped = (req: any): Promise<any> => (syncEntitlement as any).run(req);

const HOME = 'home-sync';
const OWNER = 'owner-sync';
const MEMBER = 'member-sync';

// El helper parseReceiptData en sync_entitlement_helpers.ts parsea un JSON
// con campos { status, plan, endsAt, autoRenewEnabled }
const validActiveReceipt = JSON.stringify({
  status: 'active',
  plan: 'monthly',
  endsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  autoRenewEnabled: true,
});
const expiredReceipt = JSON.stringify({
  status: 'expired',
  plan: 'monthly',
  endsAt: new Date(Date.now() - 1000).toISOString(),
  autoRenewEnabled: false,
});

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
});


describe('syncEntitlement — happy path', () => {
  it('receipt válido activa premium en el hogar', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: validActiveReceipt,
      platform: 'ios',
      chargeId: 'charge-test-001',
    }));

    expect(result.success).toBe(true);
    expect(result.premiumStatus).toBe('active');

    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('active');
    expect(homeDoc.data()!['currentPayerUid']).toBe(OWNER);
  });

  it('receipt válido crea doc en subscriptions/history/charges', async () => {
    const chargeDoc = await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('charge-test-001')
      .get();
    expect(chargeDoc.exists).toBe(true);
    expect(chargeDoc.data()!['status']).toBe('active');
  });

  it('receipt válido actualiza premiumFlags en dashboard', async () => {
    const dashDoc = await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dashDoc.data()?.['premiumFlags']?.['isPremium']).toBe(true);
  });

  it('llamada idempotente con mismo chargeId no duplica slot unlock', async () => {
    // Segunda llamada con mismo chargeId → validForUnlock = false
    await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: validActiveReceipt,
      platform: 'ios',
      chargeId: 'charge-test-001',
    }));
    const chargeDoc = await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('charge-test-001')
      .get();
    expect(chargeDoc.data()!['validForUnlock']).toBe(false);
  });

  it('receipt expirado deja premiumStatus = expired', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: expiredReceipt,
      platform: 'android',
      chargeId: 'charge-test-002',
    }));
    expect(result.premiumStatus).toBe('expired');
    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('expired');
  });
});

describe('syncEntitlement — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, receiptData: validActiveReceipt, platform: 'ios', chargeId: 'x' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('usuario no miembro del hogar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest('outsider-sync', {
        homeId: HOME, receiptData: validActiveReceipt, platform: 'ios', chargeId: 'charge-x',
      }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('campos requeridos vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: '', receiptData: '', platform: 'ios', chargeId: '',
      }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
