// functions/test/integration/sync_entitlement_idempotency.test.ts
//
// Idempotencia END-TO-END contra el emulador Firestore (sustituye al antiguo
// "test espejo" que reimplementaba la lógica). Verifica el bug del premortek #02:
// una segunda llamada con el MISMO chargeId NO debe extender premiumEndsAt ni
// duplicar el slot, porque ahora TODA la escritura del hogar ocurre dentro de la
// transacción guardada por chargeSnap.exists.
//
// Las APIs de store se mockean vía __setReceiptVerifiersForTesting (sin red).

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

const HOME = 'home-idem';
const OWNER = 'owner-idem';

const androidReceipt = JSON.stringify({
  productId: 'toka_premium_annual',
  purchaseToken: 'sub-token-STABLE',
  transactionId: 'GPA.0001',
  source: 'google_play',
});

function verified(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active',
    plan: 'annual',
    endsAt: new Date('2027-01-01T00:00:00.000Z'),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: 'sub-token-STABLE',
    productId: 'toka_premium_annual',
    ...over,
  };
}

function installVerifier(impl: () => Promise<VerifiedReceipt>) {
  const verifiers: ReceiptVerifiers = { verifyGooglePlay: impl };
  __setReceiptVerifiersForTesting(verifiers);
}

let prevFunctionsEmulator: string | undefined;
beforeAll(() => {
  // El gate de la callable permite operar en el emulador.
  prevFunctionsEmulator = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = 'true';
});

afterAll(() => {
  __setReceiptVerifiersForTesting(undefined);
  if (prevFunctionsEmulator === undefined) delete process.env.FUNCTIONS_EMULATOR;
  else process.env.FUNCTIONS_EMULATOR = prevFunctionsEmulator;
});

beforeEach(async () => {
  await cleanAll();
  await createUser(OWNER, { lifetimeUnlockedHomeSlots: 0, homeSlotCap: 2 });
  await createHome(HOME, OWNER);
});

describe('syncEntitlement — idempotencia del estado del hogar', () => {
  it('recibo válido verificado → activa Premium UNA vez y desbloquea 1 slot', async () => {
    installVerifier(async () => verified({}));

    const res = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));
    expect(res.premiumStatus).toBe('active');

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('active');
    expect(home['currentPayerUid']).toBe(OWNER);
    expect((home['premiumEndsAt'] as FirebaseFirestore.Timestamp).toDate().toISOString())
      .toBe('2027-01-01T00:00:00.000Z');

    const user = (await getDb().collection('users').doc(OWNER).get()).data()!;
    expect(user['lifetimeUnlockedHomeSlots']).toBe(1);
  });

  it('doble llamada con MISMO chargeId → NO extiende premiumEndsAt ni duplica slot', async () => {
    // El verificador devuelve un endsAt MÁS TARDÍO en la 2ª llamada. Si la
    // escritura del hogar no estuviese protegida por la transacción, el hogar
    // saltaría a esa fecha posterior. Debe quedarse en la 1ª.
    let call = 0;
    installVerifier(async () => {
      call += 1;
      return verified({
        endsAt: call === 1
          ? new Date('2027-01-01T00:00:00.000Z')
          : new Date('2099-01-01T00:00:00.000Z'),
      });
    });

    await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));
    await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    // premiumEndsAt NO saltó a 2099 — la 2ª llamada fue idempotente.
    expect((home['premiumEndsAt'] as FirebaseFirestore.Timestamp).toDate().toISOString())
      .toBe('2027-01-01T00:00:00.000Z');

    // El slot no se duplicó.
    const user = (await getDb().collection('users').doc(OWNER).get()).data()!;
    expect(user['lifetimeUnlockedHomeSlots']).toBe(1);

    // Solo existe un doc de cargo y marca validForUnlock.
    const charge = (await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('sub-token-STABLE').get()).data()!;
    expect(charge['validForUnlock']).toBe(true);
    expect(charge['storeVerified']).toBe(true);
  });

  it('recibo verificado como EXPIRADO → no activa Premium ni desbloquea slot', async () => {
    installVerifier(async () => verified({
      status: 'expired',
      endsAt: new Date('2020-01-01T00:00:00.000Z'),
    }));

    const res = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));
    expect(res.premiumStatus).toBe('expired');

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('expired');

    const user = (await getDb().collection('users').doc(OWNER).get()).data()!;
    expect(user['lifetimeUnlockedHomeSlots']).toBe(0);
  });

  it('recibo verificado pero SIN verificación de store (inferencia) → activa Premium pero NO desbloquea plaza permanente', async () => {
    // Sin verificador inyectado: cae a inferencia (storeVerified=false).
    __setReceiptVerifiersForTesting(undefined);
    delete process.env.STRICT_RECEIPT_VALIDATION;

    const res = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }));
    expect(res.premiumStatus).toBe('active');

    const user = (await getDb().collection('users').doc(OWNER).get()).data()!;
    // storeVerified=false → NUNCA acumula plazas permanentes falsas.
    expect(user['lifetimeUnlockedHomeSlots']).toBe(0);

    const charge = (await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('sub-token-STABLE').get()).data()!;
    expect(charge['validForUnlock']).toBe(false);
    expect(charge['storeVerified']).toBe(false);
  });

  it('verificador que LANZA (token corrupto) → la callable rechaza y el hogar sigue Free', async () => {
    installVerifier(async () => { throw new Error('google-play-verify-failed-400'); });

    await expect(wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, receiptData: androidReceipt, platform: 'android',
    }))).rejects.toThrow();

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('free');
  });
});
