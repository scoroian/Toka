// functions/test/integration/entitlement_reconciliation.test.ts
//
// Reconciliación del estado Premium con las stores (Hallazgo #06), contra el
// emulador Firestore. Ejercita la lógica REAL de los handlers (handleRtdnEvent /
// handleAsnEvent) y del núcleo compartido (reconcile/revoke), sin simular la
// entrega Pub/Sub ni la red de las stores (verificador inyectado).

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb,
} from './helpers/setup';
import { parseRtdnMessage, handleRtdnEvent, RTDN_TYPE } from '../../src/entitlement/google_rtdn';
import { decodeAppStoreNotification, handleAsnEvent } from '../../src/entitlement/app_store_notifications';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

function futureTs(days: number) {
  return Timestamp.fromDate(new Date(Date.now() + days * 24 * 3600 * 1000));
}

/**
 * Siembra un hogar Premium con su pagador, una plaza concedida (slotLedger) y el
 * índice de compra (purchaseIndex) que mapea chargeId → hogar/pagador.
 */
async function seedPremiumHome(opts: {
  homeId: string;
  uid: string;
  chargeId: string;
  platform: 'ios' | 'android';
  productId: string;
  endsAtDays: number;
}): Promise<void> {
  const db = getDb();
  await createUser(opts.uid, {
    baseHomeSlots: 2,
    lifetimeUnlockedHomeSlots: 1,
    homeSlotCap: 3,
  });
  await createHome(opts.homeId, opts.uid, {
    premiumStatus: 'active',
    premiumPlan: opts.productId.includes('annual') ? 'annual' : 'monthly',
    premiumEndsAt: futureTs(opts.endsAtDays),
    autoRenewEnabled: true,
    currentPayerUid: opts.uid,
    limits: { maxMembers: 10, maxTasks: 50 },
  });
  // Plaza concedida por este cargo.
  await db.collection('users').doc(opts.uid)
    .collection('slotLedger').doc(opts.chargeId)
    .set({
      sourceType: 'premium_purchase',
      chargeId: opts.chargeId,
      validForUnlock: true,
      slotNumber: 1,
      unlockedAt: FieldValue.serverTimestamp(),
    });
  // Cargo en el historial.
  await db.collection('homes').doc(opts.homeId)
    .collection('subscriptions').doc('history')
    .collection('charges').doc(opts.chargeId)
    .set({ chargeId: opts.chargeId, uid: opts.uid, status: 'active', storeVerified: true });
  // Índice chargeId → hogar/pagador (lo escribe syncEntitlement en producción).
  await db.collection('purchaseIndex').doc(opts.chargeId).set({
    homeId: opts.homeId,
    uid: opts.uid,
    platform: opts.platform,
    productId: opts.productId,
    updatedAt: FieldValue.serverTimestamp(),
  });
  // Membership del pagador (para billingState).
  await db.collection('users').doc(opts.uid)
    .collection('memberships').doc(opts.homeId)
    .set({ role: 'owner', status: 'active', billingState: 'currentPayer' }, { merge: true });
  // Dashboard premium.
  await db.collection('homes').doc(opts.homeId)
    .collection('views').doc('dashboard')
    .set({
      premiumFlags: { isPremium: true, showAds: false },
      adFlags: { showBanner: false },
    }, { merge: true });
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

function verified(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active',
    plan: 'monthly',
    endsAt: new Date(Date.now() + 35 * 24 * 3600 * 1000),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: 'gp-token',
    productId: 'toka_premium_monthly',
    ...over,
  };
}

beforeAll(async () => {
  await cleanAll();
});

describe('RTDN Google — refund/revoke revoca Premium y plaza', () => {
  const HOME = 'home-rtdn-refund';
  const OWNER = 'owner-rtdn-refund';
  const CHARGE = 'gp-token-refund-1';

  beforeAll(async () => {
    await seedPremiumHome({
      homeId: HOME, uid: OWNER, chargeId: CHARGE,
      platform: 'android', productId: 'toka_premium_monthly', endsAtDays: 20,
    });
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: CHARGE, subscriptionId: 'toka_premium_monthly' },
    });
    // No hace falta verificador: el revoke no re-verifica.
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
  });

  it('hogar → expiredFree (Premium revocado)', async () => {
    const home = await getDb().collection('homes').doc(HOME).get();
    expect(home.data()!['premiumStatus']).toBe('expiredFree');
    expect(home.data()!['autoRenewEnabled']).toBe(false);
  });

  it('dashboard → ads ON (isPremium false, showAds true)', async () => {
    const dash = await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dash.data()!['premiumFlags']['isPremium']).toBe(false);
    expect(dash.data()!['premiumFlags']['showAds']).toBe(true);
    expect(dash.data()!['adFlags']['showBanner']).toBe(true);
  });

  it('plaza revocada: lifetimeUnlockedHomeSlots decrementado a 0 y ledger validForUnlock=false', async () => {
    const user = await getDb().collection('users').doc(OWNER).get();
    expect(user.data()!['lifetimeUnlockedHomeSlots']).toBe(0);
    expect(user.data()!['homeSlotCap']).toBe(2);
    const ledger = await getDb().collection('users').doc(OWNER)
      .collection('slotLedger').doc(CHARGE).get();
    expect(ledger.data()!['validForUnlock']).toBe(false);
  });

  it('cargo marcado refunded; pagador pasa a formerPayer', async () => {
    const charge = await getDb().collection('homes').doc(HOME)
      .collection('subscriptions').doc('history').collection('charges').doc(CHARGE).get();
    expect(charge.data()!['status']).toBe('refunded');
    const membership = await getDb().collection('users').doc(OWNER)
      .collection('memberships').doc(HOME).get();
    expect(membership.data()!['billingState']).toBe('formerPayer');
  });

  it('idempotente: re-procesar el refund no vuelve a decrementar la plaza', async () => {
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: CHARGE },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const user = await getDb().collection('users').doc(OWNER).get();
    expect(user.data()!['lifetimeUnlockedHomeSlots']).toBe(0); // sigue en 0, no en -1
  });
});

describe('RTDN Google — voidedPurchaseNotification también revoca', () => {
  const HOME = 'home-rtdn-void';
  const OWNER = 'owner-rtdn-void';
  const CHARGE = 'gp-token-void-1';

  it('voided → hogar expiredFree y plaza revocada', async () => {
    await seedPremiumHome({
      homeId: HOME, uid: OWNER, chargeId: CHARGE,
      platform: 'android', productId: 'toka_premium_monthly', endsAtDays: 20,
    });
    const msg = encodeRtdn({ voidedPurchaseNotification: { purchaseToken: CHARGE, refundType: 1 } });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {});
    const home = await getDb().collection('homes').doc(HOME).get();
    expect(home.data()!['premiumStatus']).toBe('expiredFree');
    const user = await getDb().collection('users').doc(OWNER).get();
    expect(user.data()!['lifetimeUnlockedHomeSlots']).toBe(0);
  });
});

describe('RTDN Google — renovación extiende premiumEndsAt', () => {
  const HOME = 'home-rtdn-renew';
  const OWNER = 'owner-rtdn-renew';
  const CHARGE = 'gp-token-renew-1';

  it('RENEWED re-verifica y extiende el periodo', async () => {
    await seedPremiumHome({
      homeId: HOME, uid: OWNER, chargeId: CHARGE,
      platform: 'android', productId: 'toka_premium_monthly', endsAtDays: 5,
    });
    const before = (await getDb().collection('homes').doc(HOME).get())
      .data()!['premiumEndsAt'] as admin.firestore.Timestamp;

    const newEndsAt = new Date(Date.now() + 35 * 24 * 3600 * 1000);
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: 2 /* RENEWED */, purchaseToken: CHARGE, subscriptionId: 'toka_premium_monthly' },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verified({ chargeId: CHARGE, endsAt: newEndsAt, status: 'active' }),
    });

    const home = await getDb().collection('homes').doc(HOME).get();
    expect(home.data()!['premiumStatus']).toBe('active');
    const after = home.data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    expect(after.toMillis()).toBeGreaterThan(before.toMillis());
    expect(after.toMillis()).toBe(newEndsAt.getTime());
  });

  it('notificación fuera de orden con endsAt anterior NO acorta el periodo', async () => {
    const before = (await getDb().collection('homes').doc(HOME).get())
      .data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    const earlier = new Date(Date.now() + 1 * 24 * 3600 * 1000);
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: 2, purchaseToken: CHARGE },
    });
    await handleRtdnEvent(getDb(), parseRtdnMessage(msg), {
      verifyGooglePlay: async () => verified({ chargeId: CHARGE, endsAt: earlier, status: 'active' }),
    });
    const after = (await getDb().collection('homes').doc(HOME).get())
      .data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    expect(after.toMillis()).toBe(before.toMillis()); // sin cambios (max)
  });
});

describe('App Store ASN v2 — re-verifica SIEMPRE contra Apple (webhook público)', () => {
  const HOME = 'home-asn-refund';
  const OWNER = 'owner-asn-refund';
  const CHARGE = 'orig-tx-asn-1';

  // Verificador Apple inyectado (en prod = App Store Server API real).
  const verifyApple = (over: Partial<VerifiedReceipt>) =>
    async (): Promise<VerifiedReceipt> => verified({ chargeId: CHARGE, plan: 'annual', productId: 'toka_premium_annual', ...over });

  it('REFUND confirmado por Apple (status expired) → hogar expiredFree y plaza revocada', async () => {
    await seedPremiumHome({
      homeId: HOME, uid: OWNER, chargeId: CHARGE,
      platform: 'ios', productId: 'toka_premium_annual', endsAtDays: 200,
    });
    const signedTransactionInfo = fakeJws({
      originalTransactionId: CHARGE, productId: 'toka_premium_annual',
      expiresDate: Date.now() + 200 * 24 * 3600 * 1000,
    });
    const signedPayload = fakeJws({
      notificationType: 'REFUND',
      data: { bundleId: 'com.toka.app', environment: 'Production', status: 5, signedTransactionInfo },
    });
    // Apple confirma el refund: la suscripción ya no da acceso.
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: verifyApple({ status: 'expired', endsAt: new Date(Date.now() - 1000) }),
    });

    const home = await getDb().collection('homes').doc(HOME).get();
    expect(home.data()!['premiumStatus']).toBe('expiredFree');
    const user = await getDb().collection('users').doc(OWNER).get();
    expect(user.data()!['lifetimeUnlockedHomeSlots']).toBe(0);
  });

  it('SEGURIDAD: REFUND forjado pero Apple reporta ACTIVO → NO revoca (sin griefing)', async () => {
    const HOMEF = 'home-asn-forged';
    const OWNERF = 'owner-asn-forged';
    const CHARGEF = 'orig-tx-asn-forged';
    await seedPremiumHome({
      homeId: HOMEF, uid: OWNERF, chargeId: CHARGEF,
      platform: 'ios', productId: 'toka_premium_annual', endsAtDays: 100,
    });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGEF, productId: 'toka_premium_annual', expiresDate: Date.now() + 100 * 24 * 3600 * 1000 });
    const signedPayload = fakeJws({ notificationType: 'REFUND', data: { bundleId: 'com.toka.app', signedTransactionInfo } });
    // Atacante hace POST de un REFUND, pero Apple dice que sigue activa.
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: async (): Promise<VerifiedReceipt> => verified({ chargeId: CHARGEF, plan: 'annual', productId: 'toka_premium_annual', status: 'active', endsAt: new Date(Date.now() + 100 * 24 * 3600 * 1000) }),
    });
    const home = await getDb().collection('homes').doc(HOMEF).get();
    expect(home.data()!['premiumStatus']).toBe('active'); // Premium INTACTO
    const user = await getDb().collection('users').doc(OWNERF).get();
    expect(user.data()!['lifetimeUnlockedHomeSlots']).toBe(1); // plaza INTACTA
  });

  it('SEGURIDAD: sin verificador configurado → NO confía en el cuerpo (no cambia nada)', async () => {
    const HOMEN = 'home-asn-noverify';
    const OWNERN = 'owner-asn-noverify';
    const CHARGEN = 'orig-tx-asn-noverify';
    await seedPremiumHome({ homeId: HOMEN, uid: OWNERN, chargeId: CHARGEN, platform: 'ios', productId: 'toka_premium_monthly', endsAtDays: 10 });
    const signedTransactionInfo = fakeJws({ originalTransactionId: CHARGEN, productId: 'toka_premium_monthly', expiresDate: Date.now() + 365 * 24 * 3600 * 1000 });
    // DID_RENEW forjado pretendiendo extender un año, SIN verificador disponible.
    const signedPayload = fakeJws({ notificationType: 'DID_RENEW', data: { bundleId: 'com.toka.app', signedTransactionInfo } });
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {}); // deps sin verifyAppStore
    const home = await getDb().collection('homes').doc(HOMEN).get();
    // premiumEndsAt NO se extendió (el cuerpo se ignoró).
    const endsAt = home.data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    expect(endsAt.toMillis()).toBeLessThan(Date.now() + 20 * 24 * 3600 * 1000);
  });

  it('DID_RENEW → re-verifica y extiende premiumEndsAt', async () => {
    const HOME2 = 'home-asn-renew';
    const OWNER2 = 'owner-asn-renew';
    const CHARGE2 = 'orig-tx-asn-2';
    await seedPremiumHome({
      homeId: HOME2, uid: OWNER2, chargeId: CHARGE2,
      platform: 'ios', productId: 'toka_premium_monthly', endsAtDays: 3,
    });
    const before = (await getDb().collection('homes').doc(HOME2).get())
      .data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    const newExpires = Date.now() + 33 * 24 * 3600 * 1000;
    const signedTransactionInfo = fakeJws({
      originalTransactionId: CHARGE2, productId: 'toka_premium_monthly', expiresDate: newExpires,
    });
    const signedRenewalInfo = fakeJws({ autoRenewStatus: 1 });
    const signedPayload = fakeJws({
      notificationType: 'DID_RENEW',
      data: { bundleId: 'com.toka.app', status: 1, signedTransactionInfo, signedRenewalInfo },
    });
    // Apple confirma la renovación con el nuevo expiry.
    await handleAsnEvent(getDb(), decodeAppStoreNotification(signedPayload), {
      verifyAppStore: async (): Promise<VerifiedReceipt> => verified({ chargeId: CHARGE2, plan: 'monthly', productId: 'toka_premium_monthly', status: 'active', endsAt: new Date(newExpires) }),
    });

    const home = await getDb().collection('homes').doc(HOME2).get();
    expect(home.data()!['premiumStatus']).toBe('active');
    const after = home.data()!['premiumEndsAt'] as admin.firestore.Timestamp;
    expect(after.toMillis()).toBeGreaterThan(before.toMillis());
    expect(after.toMillis()).toBe(newExpires);
  });
});

describe('Robustez — notificación sin purchaseIndex no rompe (ack)', () => {
  it('RTDN de un token desconocido → no lanza, no escribe', async () => {
    const msg = encodeRtdn({
      subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: 'token-inexistente' },
    });
    await expect(handleRtdnEvent(getDb(), parseRtdnMessage(msg), {})).resolves.toBeUndefined();
  });
});
