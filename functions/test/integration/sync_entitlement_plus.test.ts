// functions/test/integration/sync_entitlement_plus.test.ts
//
// Ruta "Toka Plus" de la callable syncEntitlement: un SKU de Plus escribe el
// eje de entitlement INDIVIDUAL (users/{uid}/entitlements/plus) y el índice de
// compra con kind='plus', SIN tocar el hogar. Demuestra el aislamiento
// per-usuario y que Plus no exige membresía de hogar.

import {
  cleanAll, createUser, createHome, getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';
import {
  __setReceiptVerifiersForTesting,
  type ReceiptVerifiers,
} from '../../src/entitlement/sync_entitlement_helpers';
import { plusEntitlementRef } from '../../src/entitlement/plus_entitlement';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const wrapped = (req: any): Promise<any> => (syncEntitlement as any).run(req);

const BUYER = 'plus-buyer';      // compra Plus, NO necesita ser miembro de ningún hogar
const HOME = 'plus-sync-home';
const HOME_OWNER = 'plus-sync-owner';

function plusReceipt(productId: string, token: string): string {
  return JSON.stringify({
    productId, purchaseToken: token, transactionId: 'TX.' + token, source: 'google_play',
  });
}

function verifiedPlus(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active',
    plan: 'monthly',
    endsAt: new Date(Date.now() + 31 * 24 * 3600 * 1000),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: 'plus-sync-token-1',
    productId: 'toka_plus_monthly',
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
  await createUser(BUYER);
  await createUser(HOME_OWNER);
  // Hogar Free para verificar que la compra de Plus NO lo toca.
  await createHome(HOME, HOME_OWNER, { premiumStatus: 'free', premiumTier: null });
});

afterAll(() => {
  __setReceiptVerifiersForTesting(undefined);
  if (prevFunctionsEmulator === undefined) delete process.env.FUNCTIONS_EMULATOR;
  else process.env.FUNCTIONS_EMULATOR = prevFunctionsEmulator;
});

describe('syncEntitlement — ruta Toka Plus (eje per-usuario)', () => {
  it('SKU Plus mensual escribe users/{uid}/entitlements/plus activo (no toca hogar)', async () => {
    installVerifier(async () => verifiedPlus({ chargeId: 'plus-sync-token-1' }));
    const result = await wrapped(makeCallableRequest(BUYER, {
      homeId: HOME, // se ignora para Plus
      receiptData: plusReceipt('toka_plus_monthly', 'plus-sync-token-1'),
      platform: 'android',
    }));

    expect(result.success).toBe(true);
    expect(result.plus).toEqual({ status: 'active', active: true, cycle: 'monthly' });

    const plus = (await plusEntitlementRef(getDb(), BUYER).get()).data()!;
    expect(plus['status']).toBe('active');
    expect(plus['active']).toBe(true);
    expect(plus['cycle']).toBe('monthly');
    expect(plus['productId']).toBe('toka_plus_monthly');
    expect(plus['source']).toBe('purchase');

    // El hogar NO cambia: Plus es ortogonal.
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('free');
    expect(home['premiumTier']).toBeNull();
    expect(home['currentPayerUid']).toBeUndefined();
  });

  it('escribe purchaseIndex con kind="plus" y uid (sin homeId del hogar)', async () => {
    const idx = (await getDb().collection('purchaseIndex').doc('plus-sync-token-1').get()).data()!;
    expect(idx['kind']).toBe('plus');
    expect(idx['uid']).toBe(BUYER);
    expect(idx['productId']).toBe('toka_plus_monthly');
  });

  it('SKU Plus anual fija cycle=annual', async () => {
    installVerifier(async () => verifiedPlus({
      chargeId: 'plus-sync-token-annual', productId: 'toka_plus_annual', plan: 'annual',
      endsAt: new Date(Date.now() + 365 * 24 * 3600 * 1000),
    }));
    const result = await wrapped(makeCallableRequest(BUYER, {
      homeId: HOME,
      receiptData: plusReceipt('toka_plus_annual', 'plus-sync-token-annual'),
      platform: 'android',
    }));
    expect(result.plus.cycle).toBe('annual');
  });

  it('Plus NO requiere ser miembro del hogar (compra solo con auth)', async () => {
    // BUYER no es miembro de HOME (solo HOME_OWNER lo es) y aun así pudo comprar.
    const member = await getDb().collection('homes').doc(HOME).collection('members').doc(BUYER).get();
    expect(member.exists).toBe(false);
  });

  it('recibo Plus expirado deja active=false', async () => {
    const U = 'plus-buyer-expired';
    await createUser(U);
    installVerifier(async () => verifiedPlus({
      chargeId: 'plus-sync-token-exp', status: 'expired',
      endsAt: new Date('2020-01-01T00:00:00.000Z'),
    }));
    const result = await wrapped(makeCallableRequest(U, {
      homeId: HOME, receiptData: plusReceipt('toka_plus_monthly', 'plus-sync-token-exp'),
      platform: 'android',
    }));
    expect(result.plus.active).toBe(false);
    const plus = (await plusEntitlementRef(getDb(), U).get()).data()!;
    expect(plus['active']).toBe(false);
  });

  it('idempotente: reprocesar el mismo recibo Plus no extiende endsAt', async () => {
    const U = 'plus-buyer-idem';
    await createUser(U);
    const ends = new Date(Date.now() + 31 * 24 * 3600 * 1000);
    installVerifier(async () => verifiedPlus({ chargeId: 'plus-sync-token-idem', endsAt: ends }));
    await wrapped(makeCallableRequest(U, {
      homeId: HOME, receiptData: plusReceipt('toka_plus_monthly', 'plus-sync-token-idem'),
      platform: 'android',
    }));
    const first = (await plusEntitlementRef(getDb(), U).get()).data()!;
    const startsAt1 = (first['startsAt'] as any).toMillis();

    await wrapped(makeCallableRequest(U, {
      homeId: HOME, receiptData: plusReceipt('toka_plus_monthly', 'plus-sync-token-idem'),
      platform: 'android',
    }));
    const second = (await plusEntitlementRef(getDb(), U).get()).data()!;
    expect((second['startsAt'] as any).toMillis()).toBe(startsAt1);
  });

  it('sin autenticación → unauthenticated (también en ruta Plus)', async () => {
    await expect(
      wrapped({
        data: { homeId: HOME, receiptData: plusReceipt('toka_plus_monthly', 't'), platform: 'android' },
        auth: null, rawRequest: {},
      })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
