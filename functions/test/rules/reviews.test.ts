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
const EVENT1 = 'event1';
const REVIEWER_UID = 'reviewer1';
const PERFORMER_UID = 'performer1';
const THIRD_MEMBER_UID = 'member3';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-reviews',
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

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: REVIEWER_UID });

    // El taskEvent contiene performerUid — necesario para la rule de reviews
    await setDoc(doc(db, `homes/${HOME1}/taskEvents/${EVENT1}`), {
      performerUid: PERFORMER_UID,
      taskId: 'task1',
    });

    // Review cuyo doc ID es el uid del autor (reviewerUid)
    await setDoc(
      doc(db, `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`),
      { rating: 5, note: 'Buen trabajo' }
    );

    await setDoc(doc(db, `users/${REVIEWER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${PERFORMER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    await setDoc(doc(db, `users/${THIRD_MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    // OUTSIDER_UID sin membresía
  });
});

describe('reviews security rules', () => {
  it('autor de review puede leer su review', async () => {
    const ctx = testEnv.authenticatedContext(REVIEWER_UID);
    await assertSucceeds(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('evaluado puede leer la review sobre él', async () => {
    const ctx = testEnv.authenticatedContext(PERFORMER_UID);
    await assertSucceeds(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('tercero miembro del hogar NO puede leer la nota textual', async () => {
    const ctx = testEnv.authenticatedContext(THIRD_MEMBER_UID);
    await assertFails(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });

  it('usuario externo NO puede leer ninguna review', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(
      getDoc(
        doc(ctx.firestore(), `homes/${HOME1}/taskEvents/${EVENT1}/reviews/${REVIEWER_UID}`)
      )
    );
  });
});
