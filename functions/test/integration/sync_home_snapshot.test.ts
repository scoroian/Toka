// functions/test/integration/sync_home_snapshot.test.ts
//
// Mejora/bug §10 (QA 2026-06-16): el avatar (y el nombre) del hogar no llegaban
// al selector de hogares ni a "Mis hogares", que pintan desde el snapshot
// denormalizado de la membership (`homeNameSnapshot`/`homePhotoSnapshot`), no
// del documento del hogar en vivo. El trigger syncHomeSnapshotToMemberships
// mantiene ese snapshot fresco cuando cambia `name`/`photoUrl` del hogar.
// Aquí ejercitamos el trigger real contra el emulador de Firestore.

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb, makeCallableRequest,
} from './helpers/setup';
import {
  syncHomeSnapshotToMemberships, joinHomeByCode,
} from '../../src/homes/index';

const wrappedJoinByCode = (req: any): Promise<any> => (joinHomeByCode as any).run(req);

function futureTs(): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));
}

// El handler solo usa event.data.before/after.data() y event.params.homeId, así
// que construimos un evento mínimo sin depender de firebase-functions-test.
const runHomeTrigger = (homeId: string, before: any, after: any): Promise<any> =>
  (syncHomeSnapshotToMemberships as any).run({
    params: { homeId },
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
  });

async function membershipSnapshot(uid: string, homeId: string) {
  const doc = await getDb()
    .collection('users').doc(uid)
    .collection('memberships').doc(homeId)
    .get();
  return doc.data() ?? {};
}

const OWNER = 'snap-owner';
const MEMBER = 'snap-member';
const FROZEN = 'snap-frozen';
const LEFT = 'snap-left';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER, { nickname: 'Owner' });
  await createUser(MEMBER, { nickname: 'Member' });
  await createUser(FROZEN, { nickname: 'Frozen' });
  await createUser(LEFT, { nickname: 'Left' });
});

describe('syncHomeSnapshotToMemberships', () => {
  const HOME = 'home-snap';

  beforeAll(async () => {
    await createHome(HOME, OWNER, { name: 'Casa Vieja' });
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
    // Miembro que abandonó: su member doc queda fuera del filtro active/frozen.
    await addMemberToHome(HOME, LEFT, 'member', 'active');
    await getDb().collection('homes').doc(HOME).collection('members').doc(LEFT)
      .update({ status: 'left' });
  });

  it('propaga nombre y foto nuevos a memberships activas y congeladas', async () => {
    await runHomeTrigger(
      HOME,
      { name: 'Casa Vieja' },
      { name: 'Casa Nueva', photoUrl: 'https://x.y/casa.jpg' },
    );

    for (const uid of [OWNER, MEMBER, FROZEN]) {
      const m = await membershipSnapshot(uid, HOME);
      expect(m['homeNameSnapshot']).toBe('Casa Nueva');
      expect(m['homePhotoSnapshot']).toBe('https://x.y/casa.jpg');
    }
  });

  it('no toca la membership de un miembro que abandonó (status=left)', async () => {
    const m = await membershipSnapshot(LEFT, HOME);
    // addMemberToHome no escribe el snapshot; el trigger lo dejó intacto.
    expect(m['homeNameSnapshot']).toBeUndefined();
    expect(m['homePhotoSnapshot']).toBeUndefined();
  });

  it('al borrar la foto del hogar deja homePhotoSnapshot=null', async () => {
    await runHomeTrigger(
      HOME,
      { name: 'Casa Nueva', photoUrl: 'https://x.y/casa.jpg' },
      { name: 'Casa Nueva' }, // photoUrl ausente == foto borrada
    );

    const m = await membershipSnapshot(MEMBER, HOME);
    expect(m['homeNameSnapshot']).toBe('Casa Nueva');
    expect(m['homePhotoSnapshot']).toBeNull();
  });

  it('es no-op cuando solo cambia un campo irrelevante (premiumStatus)', async () => {
    // Dejamos un snapshot conocido y verificamos que un cambio de premiumStatus
    // no reescribe nada (mismo nombre, misma foto).
    await runHomeTrigger(
      HOME,
      { name: 'Casa Nueva', photoUrl: 'https://x.y/v2.jpg' },
      { name: 'Casa Nueva', photoUrl: 'https://x.y/v2.jpg' },
    );
    const before = await membershipSnapshot(MEMBER, HOME);

    await runHomeTrigger(
      HOME,
      { name: 'Casa Nueva', photoUrl: 'https://x.y/v2.jpg', premiumStatus: 'free' },
      { name: 'Casa Nueva', photoUrl: 'https://x.y/v2.jpg', premiumStatus: 'active' },
    );
    const after = await membershipSnapshot(MEMBER, HOME);

    expect(after['homeNameSnapshot']).toBe(before['homeNameSnapshot']);
    expect(after['homePhotoSnapshot']).toBe(before['homePhotoSnapshot']);
  });
});

describe('joinHomeByCode — denormaliza la foto del hogar en la membership', () => {
  const HOME = 'home-join-photo';
  const JOINER = 'joiner-sees-photo';
  const INV = 'inv-join-photo';
  const CODE = 'PHOTO1';

  beforeAll(async () => {
    // Hogar que YA tiene avatar cuando el usuario se une.
    await createHome(HOME, OWNER, {
      name: 'Casa Con Foto',
      photoUrl: 'https://x.y/existing.jpg',
    });
    await createUser(JOINER, { nickname: 'Nuevo' });
    await getDb().collection('homes').doc(HOME).collection('invitations').doc(INV).set({
      code: CODE, used: false, expiresAt: futureTs(),
    });
  });

  it('la nueva membership trae homePhotoSnapshot y homeNameSnapshot del hogar', async () => {
    await wrappedJoinByCode(makeCallableRequest(JOINER, { code: CODE }));

    const m = await membershipSnapshot(JOINER, HOME);
    expect(m['homeNameSnapshot']).toBe('Casa Con Foto');
    expect(m['homePhotoSnapshot']).toBe('https://x.y/existing.jpg');
  });
});
