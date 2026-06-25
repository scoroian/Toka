// functions/test/integration/plus_reconciliation.test.ts
//
// Reconciliación del eje Toka Plus vía notificaciones de store (RTDN Google /
// ASN Apple). Reutiliza los MISMOS handlers que el eje hogar (handleRtdnEvent /
// handleAsnEvent), que bifurcan por `purchaseIndex.kind`. Verifica renovación,
// cancelación, expiración y refund del Plus, el aislamiento del hogar y la
// re-verificación obligatoria del webhook público de Apple.

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, getDb,
} from './helpers/setup';
import { parseRtdnMessage, handleRtdnEvent, RTDN_TYPE } from '../../src/entitlement/google_rtdn';
import { decodeAppStoreNotification, handleAsnEvent } from '../../src/entitlement/app_store_notifications';
import { applyPlusEntitlement, plusEntitlementRef } from '../../src/entitlement/plus_entitlement';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

function daysFromNow(days: number): Date {
  return new Date(Date.now() + days * 24 * 3600 * 1000);
}

async function seedPlus(opts: {
  uid: string; chargeId: string; platform: 'ios' | 'android';
  productId: string; endsAtDays: number;
}): Promise<void> {
  await createUser(opts.uid);
  await applyPlusEntitlement(getDb(), {
    uid: opts.uid, status: 'active',
    cycle: opts.productId.includes('annual') ? 'annual' : 'monthly',
    endsAt: daysFromNow(opts.endsAtDays), autoRenewEnabled: true,
    productId: opts.productId, platform: opts.platform,
    chargeId: opts.chargeId, source: 'purchase',
  });
  await getDb().collection('purchaseIndex').doc(opts.chargeId).set({
    uid: opts.uid, platform: opts.platform, productId: opts.productId,
    kind: 'plus', updatedAt: FieldValue.serverTimestamp(),
  });
}

function plusData(uid: string) {
  return plusEntitlementRef(getDb(), uid).get();
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

function verifiedPlus(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active', plan: 'monthly', endsAt: daysFromNow(35),
    autoRenewEnabled: true, storeVerified: true,
    chargeId: 'plus-token', productId: 'toka_plus_monthly', ...over,
  };
}

beforeAll(async () => {
  await cleanAll();
});

describe('RTDN Google — eje Plus', () => {
  it('RENEWED re-verifica y extiende endsAt del Plus', async () => {
    const UID = 'rtdn-plus-renew';
    const CHARGE = 'plus-gp-renew';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'android', productId: 'toka_plus_monthly', endsAtDays: 4 });
    const before = ((await plusData(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    const newEnds = daysFromNow(35);
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: 2, purchaseToken: CHARGE, subscriptionId: 'toka_plus_monthly' },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verifiedPlus({ chargeId: CHARGE, endsAt: newEnds, status: 'active' }),
    });
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(true);
    expect((d['endsAt'] as admin.firestore.Timestamp).toMillis()).toBeGreaterThan(before);
    expect((d['endsAt'] as admin.firestore.Timestamp).toMillis()).toBe(newEnds.getTime());
  });

  it('REVOKED (12) revoca el Plus sin re-verificar', async () => {
    const UID = 'rtdn-plus-revoke';
    const CHARGE = 'plus-gp-revoke';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'android', productId: 'toka_plus_monthly', endsAtDays: 30 });
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: CHARGE },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const d = (await plusData(UID)).data()!;
    expect(d['status']).toBe('refunded');
    expect(d['active']).toBe(false);
    expect(d['revokedReason']).toBe('google_revoked');
  });

  it('voidedPurchaseNotification también revoca el Plus', async () => {
    const UID = 'rtdn-plus-void';
    const CHARGE = 'plus-gp-void';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'android', productId: 'toka_plus_annual', endsAtDays: 200 });
    const msg = encodeRtdn({ voidedPurchaseNotification: { purchaseToken: CHARGE, refundType: 1 } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(false);
    expect(d['revokedReason']).toBe('google_voided');
  });

  it('EXPIRED re-verifica (expired) y desactiva el Plus', async () => {
    const UID = 'rtdn-plus-expired';
    const CHARGE = 'plus-gp-expired';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'android', productId: 'toka_plus_monthly', endsAtDays: 1 });
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: 13 /* EXPIRED */, purchaseToken: CHARGE },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verifiedPlus({ chargeId: CHARGE, status: 'expired', endsAt: daysFromNow(-1) }),
    });
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(false);
    expect(d['status']).toBe('expired');
  });

  it('aislamiento: revocar el Plus de un owner NO toca el premium de su hogar', async () => {
    const UID = 'rtdn-plus-iso';
    const HOME = 'rtdn-plus-iso-home';
    const CHARGE = 'plus-gp-iso';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'android', productId: 'toka_plus_monthly', endsAtDays: 30 });
    await createHome(HOME, UID, { premiumStatus: 'free', premiumTier: null });
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: CHARGE } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('free'); // intacto
  });
});

describe('App Store ASN v2 — eje Plus (re-verifica SIEMPRE)', () => {
  const verifyApple = (over: Partial<VerifiedReceipt>) =>
    async (): Promise<VerifiedReceipt> => verifiedPlus({ productId: 'toka_plus_annual', plan: 'annual', ...over });

  it('DID_RENEW re-verifica y extiende endsAt del Plus', async () => {
    const UID = 'asn-plus-renew';
    const CHARGE = 'plus-orig-renew';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'ios', productId: 'toka_plus_annual', endsAtDays: 3 });
    const before = ((await plusData(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    const newExpires = daysFromNow(370);
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_plus_annual', expiresDate: newExpires.getTime() });
    const signedRenewalInfo = fakeJws({ autoRenewStatus: 1 });
    const signedPayload = fakeJws({
      notificationType: 'DID_RENEW',
      data: { bundleId: 'com.toka.app', status: 1, signedTransactionInfo, signedRenewalInfo },
    });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: verifyApple({ chargeId: CHARGE, status: 'active', endsAt: newExpires }),
    });
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(true);
    expect((d['endsAt'] as admin.firestore.Timestamp).toMillis()).toBeGreaterThan(before);
  });

  it('REFUND confirmado por Apple (expired) revoca el Plus', async () => {
    const UID = 'asn-plus-refund';
    const CHARGE = 'plus-orig-refund';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'ios', productId: 'toka_plus_annual', endsAtDays: 300 });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_plus_annual', expiresDate: daysFromNow(300).getTime() });
    const signedPayload = fakeJws({ notificationType: 'REFUND', data: { bundleId: 'com.toka.app', status: 5, signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: verifyApple({ chargeId: CHARGE, status: 'expired', endsAt: new Date(Date.now() - 1000) }),
    });
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(false);
    expect(d['status']).toBe('refunded');
    expect(d['revokedReason']).toBe('apple_refund');
  });

  it('SEGURIDAD: REFUND forjado pero Apple reporta ACTIVO → NO revoca el Plus', async () => {
    const UID = 'asn-plus-forged';
    const CHARGE = 'plus-orig-forged';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'ios', productId: 'toka_plus_annual', endsAtDays: 100 });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_plus_annual', expiresDate: daysFromNow(100).getTime() });
    const signedPayload = fakeJws({ notificationType: 'REFUND', data: { bundleId: 'com.toka.app', signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: verifyApple({ chargeId: CHARGE, status: 'active', endsAt: daysFromNow(100) }),
    });
    const d = (await plusData(UID)).data()!;
    expect(d['active']).toBe(true);   // Plus INTACTO
    expect(d['status']).toBe('active');
  });

  it('SEGURIDAD: sin verificador → ignora el cuerpo (Plus sin cambios)', async () => {
    const UID = 'asn-plus-noverify';
    const CHARGE = 'plus-orig-noverify';
    await seedPlus({ uid: UID, chargeId: CHARGE, platform: 'ios', productId: 'toka_plus_monthly', endsAtDays: 10 });
    const before = ((await plusData(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGE, productId: 'toka_plus_monthly', expiresDate: daysFromNow(365).getTime() });
    const signedPayload = fakeJws({ notificationType: 'DID_RENEW', data: { bundleId: 'com.toka.app', signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {}); // sin verifyAppStore
    const after = ((await plusData(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    expect(after).toBe(before); // sin cambios
  });
});

describe('Robustez — notificación Plus sin purchaseIndex no rompe', () => {
  it('RTDN de token plus desconocido → no lanza', async () => {
    const msg = encodeRtdn({ subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: 'plus-desconocido' } });
    await expect(handleRtdnEvent(getDb(), parseRtdnMessage(msg), {})).resolves.toBeUndefined();
  });
});
