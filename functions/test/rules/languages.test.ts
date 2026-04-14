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

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-lang',
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
});

describe('languages security rules', () => {
  it('permite leer idiomas sin autenticación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'languages/es')));
  });

  it('deniega escribir idiomas sin autenticación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), 'languages/es'), { code: 'es' }));
  });

  it('deniega escribir idiomas con autenticación', async () => {
    const ctx = testEnv.authenticatedContext('user1');
    await assertFails(setDoc(doc(ctx.firestore(), 'languages/es'), { code: 'es' }));
  });
});
