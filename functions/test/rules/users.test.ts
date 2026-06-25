import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const USER1 = 'user1';
const USER2 = 'user2';
const HOME1 = 'home1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-users',
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
    await setDoc(doc(db, `users/${USER1}`), {
      displayName: 'User One',
      baseHomeSlots: 2,
      lifetimeUnlockedHomeSlots: 0,
      homeSlotCap: 5,
    });
    await setDoc(doc(db, `users/${USER2}`), {
      displayName: 'User Two',
      baseHomeSlots: 2,
      lifetimeUnlockedHomeSlots: 0,
      homeSlotCap: 5,
    });
    await setDoc(doc(db, `users/${USER1}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
  });
});

describe('users security rules', () => {
  it('usuario puede leer su propio perfil', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `users/${USER1}`)));
  });

  it('usuario NO puede leer perfil de otro usuario', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(getDoc(doc(ctx.firestore(), `users/${USER2}`)));
  });

  it('usuario puede actualizar su perfil', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { displayName: 'Nuevo nombre' })
    );
  });

  it('usuario NO puede modificar baseHomeSlots', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { baseHomeSlots: 10 })
    );
  });

  it('usuario NO puede modificar lifetimeUnlockedHomeSlots', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `users/${USER1}`), { lifetimeUnlockedHomeSlots: 5 })
    );
  });

  it('usuario puede leer sus membresías', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertSucceeds(
      getDoc(doc(ctx.firestore(), `users/${USER1}/memberships/${HOME1}`))
    );
  });

  it('usuario NO puede leer membresías de otro', async () => {
    const ctx = testEnv.authenticatedContext(USER1);
    await assertFails(
      getDoc(doc(ctx.firestore(), `users/${USER2}/memberships/${HOME1}`))
    );
  });

  // ─── fcmToken privado (Hallazgo #01) ──────────────────────────────────────
  describe('fcmToken vive en users/{uid} (privado)', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), `users/${USER2}`),
          { fcmToken: 'secreto-de-dispositivo-de-user2' },
          { merge: true },
        );
      });
    });

    it('un usuario NO puede leer el fcmToken de otro (está en su doc privado)', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertFails(getDoc(doc(ctx.firestore(), `users/${USER2}`)));
    });

    it('un usuario SÍ puede escribir su propio fcmToken', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertSucceeds(
        updateDoc(doc(ctx.firestore(), `users/${USER1}`), {
          fcmToken: 'mi-token',
        }),
      );
    });
  });

  // ─── Eje Toka Plus (users/{uid}/entitlements/plus) ────────────────────────
  // Lectura: SOLO el propio usuario. Escritura: SOLO backend (write: if false).
  // La proyección legible por co-miembros vive en homes/{homeId}/members/{uid}
  // .plusActive (regla de members existente), NO en este doc crudo.
  describe('entitlements/plus — lectura propia, escritura solo backend', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        const db = ctx.firestore();
        await setDoc(doc(db, `users/${USER1}/entitlements/plus`), {
          status: 'active', active: true, cycle: 'monthly',
        });
        await setDoc(doc(db, `users/${USER2}/entitlements/plus`), {
          status: 'active', active: true, cycle: 'annual',
        });
      });
    });

    it('el usuario puede leer su propio entitlement Plus', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertSucceeds(
        getDoc(doc(ctx.firestore(), `users/${USER1}/entitlements/plus`)),
      );
    });

    it('un usuario NO puede leer el Plus de otro (doc crudo privado)', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertFails(
        getDoc(doc(ctx.firestore(), `users/${USER2}/entitlements/plus`)),
      );
    });

    it('no autenticado NO puede leer el Plus', async () => {
      const ctx = testEnv.unauthenticatedContext();
      await assertFails(
        getDoc(doc(ctx.firestore(), `users/${USER1}/entitlements/plus`)),
      );
    });

    it('el cliente NO puede CREAR su Plus (write: if false)', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertFails(
        setDoc(doc(ctx.firestore(), `users/${USER1}/entitlements/nuevo`), {
          active: true,
        }),
      );
    });

    it('el cliente NO puede ACTUALIZAR su Plus', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertFails(
        updateDoc(doc(ctx.firestore(), `users/${USER1}/entitlements/plus`), {
          active: false,
        }),
      );
    });

    it('el cliente NO puede BORRAR su Plus', async () => {
      const ctx = testEnv.authenticatedContext(USER1);
      await assertFails(
        deleteDoc(doc(ctx.firestore(), `users/${USER1}/entitlements/plus`)),
      );
    });
  });
});
