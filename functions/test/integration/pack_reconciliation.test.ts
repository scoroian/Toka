// functions/test/integration/pack_reconciliation.test.ts
//
// Reconciliación del eje PACKS DE MIEMBRO vía notificaciones de store (RTDN
// Google / ASN Apple). Reutiliza los MISMOS handlers que los ejes hogar/Plus
// (handleRtdnEvent / handleAsnEvent), que bifurcan por `purchaseIndex.kind`.
// Verifica renovación (mantiene plazas), expiración/cancelación (congela
// excedentes), refund/void (revoca + congela), el aislamiento del estado premium
// del hogar y la robustez ante tokens desconocidos.

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb,
} from './helpers/setup';
import { parseRtdnMessage, handleRtdnEvent, RTDN_TYPE } from '../../src/entitlement/google_rtdn';
import { decodeAppStoreNotification, handleAsnEvent } from '../../src/entitlement/app_store_notifications';
import {
  __setHomeTiersEnabledForTesting,
  __setMemberPacksEnabledForTesting,
} from '../../src/shared/feature_flags';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

function daysFromNow(days: number): Date {
  return new Date(Date.now() + days * 24 * 3600 * 1000);
}

/** Crea un hogar Grupo con un pack activo, `extraMembers` miembros y su índice. */
async function seedPackHome(opts: {
  homeId: string; owner: string; kind: 'plus5' | 'plus10'; chargeId: string;
  productId: string; platform: 'ios' | 'android'; maxMembers: number; extraMembers: number;
}): Promise<void> {
  await createUser(opts.owner);
  await createHome(opts.homeId, opts.owner, {
    premiumStatus: 'active', premiumTier: 'grupo', premiumPlan: 'monthly',
    premiumEndsAt: Timestamp.fromDate(daysFromNow(60)), currentPayerUid: opts.owner,
    limits: { maxMembers: opts.maxMembers, maxTasks: 50 },
    memberPacks: {
      [opts.kind]: {
        status: 'active', active: true, chargeId: opts.chargeId,
        productId: opts.productId, endsAt: Timestamp.fromDate(daysFromNow(30)),
      },
    },
  });
  for (let i = 0; i < opts.extraMembers; i++) {
    await addMemberToHome(opts.homeId, `${opts.homeId}-m${i}`, 'member', 'active', { completions60d: 100 - i });
  }
  await getDb().collection('purchaseIndex').doc(opts.chargeId).set({
    homeId: opts.homeId, uid: opts.owner, platform: opts.platform,
    productId: opts.productId, kind: 'pack', updatedAt: FieldValue.serverTimestamp(),
  });
}

async function countByStatus(homeId: string, status: string): Promise<number> {
  const snap = await getDb().collection('homes').doc(homeId).collection('members').where('status', '==', status).get();
  return snap.size;
}
async function getHome(homeId: string) {
  return (await getDb().collection('homes').doc(homeId).get()).data()!;
}

function b64url(obj: unknown): string {
  return Buffer.from(JSON.stringify(obj), 'utf8').toString('base64url');
}
function fakeJws(payload: unknown): string {
  return `${b64url({ alg: 'ES256' })}.${b64url(payload)}.sig`;
}
function encodeRtdn(obj: unknown): string {
  return Buffer.from(JSON.stringify(obj), 'utf8').toString('base64');
}
function verifiedPack(productId: string, over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active', plan: productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: daysFromNow(35), autoRenewEnabled: true, storeVerified: true,
    chargeId: 'pack-token', productId, ...over,
  };
}

beforeAll(async () => {
  await cleanAll();
});
beforeEach(() => {
  __setHomeTiersEnabledForTesting(true);
  __setMemberPacksEnabledForTesting(true);
});
afterAll(() => {
  __setHomeTiersEnabledForTesting(undefined);
  __setMemberPacksEnabledForTesting(undefined);
});

describe('RTDN Google — eje pack', () => {
  it('RENOVACIÓN re-verifica y mantiene plazas (no congela)', async () => {
    const HOME = 'rtdn-pack-renew';
    const CHARGE = 'pack-gp-renew';
    // Grupo + pack +5 → cap 15, 12 activos.
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus5', chargeId: CHARGE, productId: 'toka_pack5_monthly', platform: 'android', maxMembers: 15, extraMembers: 11 });
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: 2, purchaseToken: CHARGE, subscriptionId: 'toka_pack5_monthly' } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verifiedPack('toka_pack5_monthly', { chargeId: CHARGE, endsAt: daysFromNow(60) }),
    });
    const home = await getHome(HOME);
    expect(home['limits']['maxMembers']).toBe(15);
    expect(home['memberPacks']['plus5']['active']).toBe(true);
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
  });

  it('REVOKED (12) revoca el pack y congela excedentes (15→10)', async () => {
    const HOME = 'rtdn-pack-revoke';
    const CHARGE = 'pack-gp-revoke';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus5', chargeId: CHARGE, productId: 'toka_pack5_monthly', platform: 'android', maxMembers: 15, extraMembers: 14 }); // 15 activos
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: CHARGE, subscriptionId: 'toka_pack5_monthly' } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(false);
    expect(home['memberPacks']['plus5']['status']).toBe('refunded');
    expect(home['limits']['maxMembers']).toBe(10);
    expect(await countByStatus(HOME, 'active')).toBe(10);
    expect(await countByStatus(HOME, 'frozen')).toBe(5);
    // Aislamiento: el premium del hogar NO cambia.
    expect(home['premiumStatus']).toBe('active');
    expect(home['premiumTier']).toBe('grupo');
  });

  it('voidedPurchaseNotification también revoca el pack', async () => {
    const HOME = 'rtdn-pack-void';
    const CHARGE = 'pack-gp-void';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus10', chargeId: CHARGE, productId: 'toka_pack10_annual', platform: 'android', maxMembers: 20, extraMembers: 2 });
    const msg = encodeRtdn({ voidedPurchaseNotification: { purchaseToken: CHARGE, refundType: 1 } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus10']['active']).toBe(false);
    expect(home['memberPacks']['plus10']['revokedReason']).toBe('google_voided');
    expect(home['limits']['maxMembers']).toBe(10);
  });

  it('EXPIRED re-verifica (expired) y desactiva el pack (congela)', async () => {
    const HOME = 'rtdn-pack-expired';
    const CHARGE = 'pack-gp-expired';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus5', chargeId: CHARGE, productId: 'toka_pack5_monthly', platform: 'android', maxMembers: 15, extraMembers: 12 }); // 13 activos
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: 13, purchaseToken: CHARGE, subscriptionId: 'toka_pack5_monthly' } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verifiedPack('toka_pack5_monthly', { chargeId: CHARGE, status: 'expired', endsAt: daysFromNow(-1) }),
    });
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(false);
    expect(home['limits']['maxMembers']).toBe(10);
    expect(await countByStatus(HOME, 'active')).toBe(10);
  });
});

describe('App Store ASN v2 — eje pack (re-verifica SIEMPRE)', () => {
  it('DID_RENEW re-verifica y mantiene plazas', async () => {
    const HOME = 'asn-pack-renew';
    const CHARGE = 'pack-orig-renew';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus10', chargeId: CHARGE, productId: 'toka_pack10_annual', platform: 'ios', maxMembers: 20, extraMembers: 12 });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_pack10_annual', expiresDate: daysFromNow(370).getTime() });
    const signedRenewalInfo = fakeJws({ autoRenewStatus: 1 });
    const signedPayload = fakeJws({ notificationType: 'DID_RENEW', data: { bundleId: 'com.toka.app', status: 1, signedTransactionInfo, signedRenewalInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: async () => verifiedPack('toka_pack10_annual', { chargeId: CHARGE, status: 'active', endsAt: daysFromNow(370) }),
    });
    const home = await getHome(HOME);
    expect(home['limits']['maxMembers']).toBe(20);
    expect(await countByStatus(HOME, 'frozen')).toBe(0);
  });

  it('REFUND confirmado por Apple (expired) revoca el pack y congela', async () => {
    const HOME = 'asn-pack-refund';
    const CHARGE = 'pack-orig-refund';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus5', chargeId: CHARGE, productId: 'toka_pack5_annual', platform: 'ios', maxMembers: 15, extraMembers: 14 }); // 15 activos
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_pack5_annual', expiresDate: daysFromNow(-1).getTime() });
    const signedPayload = fakeJws({ notificationType: 'REFUND', data: { bundleId: 'com.toka.app', status: 5, signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: async () => verifiedPack('toka_pack5_annual', { chargeId: CHARGE, status: 'expired', endsAt: daysFromNow(-1) }),
    });
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(false);
    expect(home['memberPacks']['plus5']['revokedReason']).toBe('apple_refund');
    expect(home['limits']['maxMembers']).toBe(10);
    expect(await countByStatus(HOME, 'frozen')).toBe(5);
  });

  it('SEGURIDAD: REFUND forjado pero Apple reporta ACTIVO → NO revoca el pack', async () => {
    const HOME = 'asn-pack-forged';
    const CHARGE = 'pack-orig-forged';
    await seedPackHome({ homeId: HOME, owner: `${HOME}-o`, kind: 'plus5', chargeId: CHARGE, productId: 'toka_pack5_annual', platform: 'ios', maxMembers: 15, extraMembers: 12 });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_pack5_annual', expiresDate: daysFromNow(100).getTime() });
    const signedPayload = fakeJws({ notificationType: 'REFUND', data: { bundleId: 'com.toka.app', signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: async () => verifiedPack('toka_pack5_annual', { chargeId: CHARGE, status: 'active', endsAt: daysFromNow(100) }),
    });
    const home = await getHome(HOME);
    expect(home['memberPacks']['plus5']['active']).toBe(true); // intacto
    expect(home['limits']['maxMembers']).toBe(15);
  });
});

describe('Robustez — notificación de pack sin purchaseIndex no rompe', () => {
  it('RTDN de token de pack desconocido → no lanza', async () => {
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: 'pack-desconocido' } });
    await expect(handleRtdnEvent(getDb(), parseRtdnMessage(msg), {})).resolves.toBeUndefined();
  });
});
