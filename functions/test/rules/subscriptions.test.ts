// functions/test/rules/subscriptions.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const CURRENT_PAYER_UID = 'payer1';
const FORMER_PAYER_UID = 'former1';
const PLAIN_MEMBER_UID = 'member1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-subscriptions-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/subscriptions/history/charge1`), {
      chargeId: 'charge1',
      plan: 'monthly',
      amount: 4.99,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'owner', billingState: 'currentPayer',
    });
    await setDoc(doc(db, `users/${CURRENT_PAYER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'admin', billingState: 'currentPayer',
    });
    await setDoc(doc(db, `users/${FORMER_PAYER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'member', billingState: 'formerPayer',
    });
    await setDoc(doc(db, `users/${PLAIN_MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'member', billingState: 'none',
    });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('subscriptions/history — read', () => {
  it('miembro con billingState currentPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(CURRENT_PAYER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('miembro con billingState formerPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(FORMER_PAYER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('owner con billingState currentPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('miembro con billingState none NO puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(PLAIN_MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('outsider autenticado NO puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('no autenticado NO puede leer historial de cargos', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });
});

// ─── WRITE (todos denegados) ───────────────────────────────────────────────────

describe('subscriptions/history — write (siempre denegado)', () => {
  it('currentPayer NO puede escribir historial directamente', async () => {
    const ctx = testEnv.authenticatedContext(CURRENT_PAYER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge2`), {
        chargeId: 'charge2', plan: 'monthly',
      })
    );
  });

  it('owner NO puede escribir historial directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge3`), {
        chargeId: 'charge3', plan: 'annual',
      })
    );
  });

  it('no autenticado NO puede escribir historial', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge4`), {
        chargeId: 'charge4', plan: 'monthly',
      })
    );
  });
});
