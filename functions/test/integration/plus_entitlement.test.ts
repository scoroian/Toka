// functions/test/integration/plus_entitlement.test.ts
//
// Núcleo del eje de entitlement INDIVIDUAL "Toka Plus" contra el emulador
// Firestore. Ejercita la lógica real de escritura/reconciliación/revocación del
// doc per-usuario `users/{uid}/entitlements/plus` y la proyección denormalizada
// `homes/{homeId}/members/{uid}.plusActive`, demostrando el aislamiento
// per-usuario (no toca el hogar ni a otros miembros).

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb,
} from './helpers/setup';
import {
  applyPlusEntitlement,
  reconcileVerifiedPlus,
  revokePlus,
  propagatePlusActiveToMembers,
  plusEntitlementRef,
} from '../../src/entitlement/plus_entitlement';
import type { VerifiedReceipt } from '../../src/entitlement/store_verifiers';

const Timestamp = admin.firestore.Timestamp;

function daysFromNow(days: number): Date {
  return new Date(Date.now() + days * 24 * 3600 * 1000);
}

function plusDoc(uid: string) {
  return plusEntitlementRef(getDb(), uid).get();
}

function verifiedPlus(over: Partial<VerifiedReceipt>): VerifiedReceipt {
  return {
    status: 'active',
    plan: 'monthly',
    endsAt: daysFromNow(31),
    autoRenewEnabled: true,
    storeVerified: true,
    chargeId: 'plus-token-1',
    productId: 'toka_plus_monthly',
    ...over,
  };
}

beforeAll(async () => {
  await cleanAll();
});

describe('applyPlusEntitlement — alta y forma del doc', () => {
  const UID = 'plus-apply-uid';

  it('alta mensual activa escribe el doc per-usuario con la forma esperada', async () => {
    await createUser(UID);
    const res = await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: daysFromNow(31),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-apply', source: 'purchase',
    });
    expect(res.active).toBe(true);
    expect(res.status).toBe('active');

    const d = (await plusDoc(UID)).data()!;
    expect(d['status']).toBe('active');
    expect(d['active']).toBe(true);
    expect(d['cycle']).toBe('monthly');
    expect(d['productId']).toBe('toka_plus_monthly');
    expect(d['platform']).toBe('android');
    expect(d['chargeId']).toBe('plus-token-apply');
    expect(d['source']).toBe('purchase');
    expect(d['autoRenewEnabled']).toBe(true);
    expect(d['startsAt']).toBeTruthy();
    expect(d['createdAt']).toBeTruthy();
    expect((d['endsAt'] as admin.firestore.Timestamp).toMillis())
      .toBeGreaterThan(Date.now());
  });

  it('alta anual fija cycle=annual', async () => {
    const UID2 = 'plus-apply-annual';
    await createUser(UID2);
    const res = await applyPlusEntitlement(getDb(), {
      uid: UID2, status: 'active', cycle: 'annual', endsAt: daysFromNow(365),
      autoRenewEnabled: true, productId: 'toka_plus_annual', platform: 'ios',
      chargeId: 'plus-token-annual', source: 'purchase',
    });
    expect(res.active).toBe(true);
    const d = (await plusDoc(UID2)).data()!;
    expect(d['cycle']).toBe('annual');
    expect(d['platform']).toBe('ios');
  });

  it('reprocesar la misma alta es idempotente: no extiende endsAt ni cambia startsAt', async () => {
    const before = (await plusDoc(UID)).data()!;
    const startsAtBefore = (before['startsAt'] as admin.firestore.Timestamp).toMillis();
    const endsAtBefore = (before['endsAt'] as admin.firestore.Timestamp).toMillis();

    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: daysFromNow(31),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-apply', source: 'purchase',
    });

    const after = (await plusDoc(UID)).data()!;
    expect((after['startsAt'] as admin.firestore.Timestamp).toMillis()).toBe(startsAtBefore);
    // endsAt con misma fecha no se extiende (max); permitir ±2s por reloj.
    expect(Math.abs((after['endsAt'] as admin.firestore.Timestamp).toMillis() - endsAtBefore))
      .toBeLessThan(2000);
  });
});

describe('applyPlusEntitlement — transiciones de estado', () => {
  const UID = 'plus-transitions-uid';

  beforeAll(async () => {
    await createUser(UID);
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: daysFromNow(5),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-tx', source: 'purchase',
    });
  });

  it('renovación extiende endsAt (toma el max)', async () => {
    const before = ((await plusDoc(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    const newEnds = daysFromNow(35);
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: newEnds,
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-tx', source: 'store_notification',
    });
    const after = ((await plusDoc(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    expect(after).toBeGreaterThan(before);
    expect(after).toBe(newEnds.getTime());
  });

  it('notificación fuera de orden con endsAt anterior NO acorta el periodo', async () => {
    const before = ((await plusDoc(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: daysFromNow(1),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-tx', source: 'store_notification',
    });
    const after = ((await plusDoc(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    expect(after).toBe(before);
  });

  it('cancelación pendiente de fin sigue activa (acceso hasta endsAt)', async () => {
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'cancelledPendingEnd', cycle: 'monthly', endsAt: daysFromNow(35),
      autoRenewEnabled: false, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-tx', source: 'store_notification',
    });
    const d = (await plusDoc(UID)).data()!;
    expect(d['status']).toBe('cancelledPendingEnd');
    expect(d['active']).toBe(true);
    expect(d['autoRenewEnabled']).toBe(false);
  });

  it('expiración: status expired ⇒ active=false', async () => {
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'expired', cycle: 'monthly', endsAt: daysFromNow(-1),
      autoRenewEnabled: false, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-token-tx', source: 'store_notification',
    });
    const d = (await plusDoc(UID)).data()!;
    expect(d['status']).toBe('expired');
    expect(d['active']).toBe(false);
  });
});

describe('propagatePlusActiveToMembers — proyección denormalizada', () => {
  const A = 'plus-prop-a';
  const B = 'plus-prop-b';
  const H1 = 'plus-prop-home1';
  const H2 = 'plus-prop-home2';

  beforeAll(async () => {
    await createUser(A);
    await createUser(B);
    await createHome(H1, A);            // A owner de H1
    await addMemberToHome(H1, B, 'member', 'active'); // B miembro de H1
    await createHome(H2, A);            // A owner de H2 también
  });

  it('escribe plusActive en members/{A} de TODOS los hogares de A, sin tocar a B', async () => {
    await propagatePlusActiveToMembers(getDb(), A, true);

    const a1 = await getDb().collection('homes').doc(H1).collection('members').doc(A).get();
    const a2 = await getDb().collection('homes').doc(H2).collection('members').doc(A).get();
    expect(a1.data()!['plusActive']).toBe(true);
    expect(a2.data()!['plusActive']).toBe(true);

    // B (co-miembro del mismo hogar) NO recibe plusActive.
    const b1 = await getDb().collection('homes').doc(H1).collection('members').doc(B).get();
    expect(b1.data()!['plusActive']).toBeUndefined();
    // B no tiene doc de entitlement Plus.
    expect((await plusDoc(B)).exists).toBe(false);
  });

  it('plusActive=false propaga la desactivación a todos los hogares', async () => {
    await propagatePlusActiveToMembers(getDb(), A, false);
    const a1 = await getDb().collection('homes').doc(H1).collection('members').doc(A).get();
    expect(a1.data()!['plusActive']).toBe(false);
  });
});

describe('applyPlusEntitlement — aislamiento per-usuario (no toca hogar ni B)', () => {
  const A = 'plus-iso-a';
  const B = 'plus-iso-b';
  const HOME = 'plus-iso-home';

  beforeAll(async () => {
    await createUser(A);
    await createUser(B);
    // Hogar Free explícito para verificar que NO cambia.
    await createHome(HOME, A, { premiumStatus: 'free', premiumTier: null });
    await addMemberToHome(HOME, B, 'member', 'active');
  });

  it('activar Plus en A no cambia premiumStatus/tier del hogar ni a B', async () => {
    await applyPlusEntitlement(getDb(), {
      uid: A, status: 'active', cycle: 'monthly', endsAt: daysFromNow(31),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-iso-charge', source: 'purchase',
    });

    const home = (await getDb().collection('homes').doc(HOME).get()).data()!;
    expect(home['premiumStatus']).toBe('free');     // hogar intacto
    expect(home['premiumTier']).toBeNull();
    expect(home['currentPayerUid']).toBeUndefined(); // Plus NO designa pagador del hogar

    // B sin Plus, su member doc sin plusActive=true.
    expect((await plusDoc(B)).exists).toBe(false);
    const bMember = (await getDb().collection('homes').doc(HOME).collection('members').doc(B).get()).data()!;
    expect(bMember['plusActive']).toBeFalsy();

    // A activo + su member doc proyectado.
    const aMember = (await getDb().collection('homes').doc(HOME).collection('members').doc(A).get()).data()!;
    expect(aMember['plusActive']).toBe(true);
  });
});

describe('revokePlus — refund / expiración revoca el eje Plus', () => {
  const UID = 'plus-revoke-uid';
  const HOME = 'plus-revoke-home';

  beforeAll(async () => {
    await createUser(UID);
    await createHome(HOME, UID);
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'annual', endsAt: daysFromNow(300),
      autoRenewEnabled: true, productId: 'toka_plus_annual', platform: 'ios',
      chargeId: 'plus-revoke-charge', source: 'purchase',
    });
  });

  it('revoca: status refunded, active=false y propaga plusActive=false', async () => {
    const out = await revokePlus(getDb(), {
      uid: UID, chargeId: 'plus-revoke-charge', reason: 'apple_refund',
    });
    expect(out.revoked).toBe(true);
    const d = (await plusDoc(UID)).data()!;
    expect(d['status']).toBe('refunded');
    expect(d['active']).toBe(false);
    expect(d['autoRenewEnabled']).toBe(false);
    expect(d['revokedReason']).toBe('apple_refund');

    const member = (await getDb().collection('homes').doc(HOME).collection('members').doc(UID).get()).data()!;
    expect(member['plusActive']).toBe(false);
  });

  it('idempotente: revocar de nuevo no rompe (sigue refunded/inactivo)', async () => {
    const out = await revokePlus(getDb(), {
      uid: UID, chargeId: 'plus-revoke-charge', reason: 'apple_refund',
    });
    expect(out.revoked).toBe(true);
    const d = (await plusDoc(UID)).data()!;
    expect(d['active']).toBe(false);
  });

  it('sin doc de Plus → revoked=false (nada que revocar)', async () => {
    const out = await revokePlus(getDb(), {
      uid: 'uid-sin-plus', chargeId: 'x', reason: 'x',
    });
    expect(out.revoked).toBe(false);
  });

  it('refund de un cargo SUPERADO no mata un Plus más reciente', async () => {
    const U = 'plus-superseded-uid';
    await createUser(U);
    // Suscripción nueva (chargeId nuevo) activa.
    await applyPlusEntitlement(getDb(), {
      uid: U, status: 'active', cycle: 'monthly', endsAt: daysFromNow(31),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-charge-NEW', source: 'purchase',
    });
    // Llega un refund de un cargo VIEJO/distinto → no debe tocar el Plus vigente.
    const out = await revokePlus(getDb(), {
      uid: U, chargeId: 'plus-charge-OLD', reason: 'google_voided',
    });
    expect(out.revoked).toBe(false);
    const d = (await plusDoc(U)).data()!;
    expect(d['active']).toBe(true);
    expect(d['status']).toBe('active');
  });
});

describe('reconcileVerifiedPlus — adaptador desde recibo verificado', () => {
  const UID = 'plus-reconcile-uid';

  beforeAll(async () => {
    await createUser(UID);
    await applyPlusEntitlement(getDb(), {
      uid: UID, status: 'active', cycle: 'monthly', endsAt: daysFromNow(3),
      autoRenewEnabled: true, productId: 'toka_plus_monthly', platform: 'android',
      chargeId: 'plus-recon-charge', source: 'purchase',
    });
  });

  it('renovación verificada extiende endsAt y deriva cycle del productId', async () => {
    const before = ((await plusDoc(UID)).data()!['endsAt'] as admin.firestore.Timestamp).toMillis();
    const newEnds = daysFromNow(33);
    const res = await reconcileVerifiedPlus(
      getDb(),
      { uid: UID, platform: 'android' },
      verifiedPlus({ chargeId: 'plus-recon-charge', endsAt: newEnds, status: 'active' }),
    );
    expect(res.active).toBe(true);
    const d = (await plusDoc(UID)).data()!;
    expect(d['cycle']).toBe('monthly');
    expect((d['endsAt'] as admin.firestore.Timestamp).toMillis()).toBeGreaterThan(before);
  });

  it('estado expired verificado desactiva Plus', async () => {
    const res = await reconcileVerifiedPlus(
      getDb(),
      { uid: UID, platform: 'android' },
      verifiedPlus({ chargeId: 'plus-recon-charge', status: 'expired', endsAt: daysFromNow(-1) }),
    );
    expect(res.active).toBe(false);
    const d = (await plusDoc(UID)).data()!;
    expect(d['active']).toBe(false);
  });
});
