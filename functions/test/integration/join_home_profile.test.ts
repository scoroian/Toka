// functions/test/integration/join_home_profile.test.ts
//
// Regresión bug #4 (QA 2026-06-16): el teléfono y su visibilidad NO se
// propagaban al doc de miembro al unirse a un hogar. Un usuario que activó
// "Mostrar mi teléfono a miembros del hogar" (users/{uid}.phoneVisibility=
// "sameHomeMembers") terminaba con un doc homes/{homeId}/members/{uid} con
// phone:null y phoneVisibility:"hidden", de modo que otros miembros nunca veían
// su teléfono. Aquí ejercitamos las callables reales joinHome / joinHomeByCode y
// el trigger syncMemberProfile contra el emulador de Firestore.

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  getDb, makeCallableRequest,
} from './helpers/setup';
import { joinHome, joinHomeByCode, syncMemberProfile } from '../../src/homes/index';

const wrappedJoinHome = (req: any): Promise<any> => (joinHome as any).run(req);
const wrappedJoinByCode = (req: any): Promise<any> => (joinHomeByCode as any).run(req);
// El handler solo usa event.data.before/after.data() y event.params.uid, así que
// construimos un evento mínimo sin depender de firebase-functions-test.
const runSyncTrigger = (uid: string, before: any, after: any): Promise<any> =>
  (syncMemberProfile as any).run({
    params: { uid },
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
  });

function futureTs(): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));
}

const OWNER = 'owner-phone';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER, { nickname: 'Owner' });
});

describe('joinHome — propaga teléfono y visibilidad al doc de miembro', () => {
  const HOME = 'home-join-phone';
  const JOINER = 'joiner-visible-phone';
  const INV = 'inv-join-phone';

  beforeAll(async () => {
    await createHome(HOME, OWNER);
    // Usuario que optó por compartir su teléfono.
    await createUser(JOINER, {
      nickname: 'Visible Vera',
      phone: '+34600111222',
      phoneVisibility: 'sameHomeMembers',
      photoUrl: 'https://x.y/vera.jpg',
    });
    await getDb().collection('homes').doc(HOME).collection('invitations').doc(INV).set({
      code: 'VERA01',
      used: false,
      expiresAt: futureTs(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  it('el nuevo miembro hereda phone y phoneVisibility de users/{uid}', async () => {
    await wrappedJoinHome(makeCallableRequest(JOINER, { homeId: HOME, invitationId: INV }));

    const member = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(JOINER).get();
    expect(member.exists).toBe(true);
    expect(member.data()!['phone']).toBe('+34600111222');
    expect(member.data()!['phoneVisibility']).toBe('sameHomeMembers');
    // nickname/photo siguen propagándose (no regresión).
    expect(member.data()!['nickname']).toBe('Visible Vera');
    expect(member.data()!['photoUrl']).toBe('https://x.y/vera.jpg');
  });
});

describe('joinHome — usuario sin teléfono mantiene defaults', () => {
  const HOME = 'home-join-nophone';
  const JOINER = 'joiner-no-phone';
  const INV = 'inv-join-nophone';

  beforeAll(async () => {
    await createHome(HOME, OWNER);
    await createUser(JOINER, { nickname: 'Sin Tel' }); // sin phone ni phoneVisibility
    await getDb().collection('homes').doc(HOME).collection('invitations').doc(INV).set({
      code: 'SIN001', used: false, expiresAt: futureTs(),
    });
  });

  it('phone null y phoneVisibility hidden por defecto', async () => {
    await wrappedJoinHome(makeCallableRequest(JOINER, { homeId: HOME, invitationId: INV }));

    const member = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(JOINER).get();
    expect(member.data()!['phone']).toBeNull();
    expect(member.data()!['phoneVisibility']).toBe('hidden');
  });
});

describe('joinHomeByCode — propaga teléfono y visibilidad', () => {
  const HOME = 'home-code-phone';
  const JOINER = 'joiner-code-phone';
  const INV = 'inv-code-phone';
  const CODE = 'CODE99';

  beforeAll(async () => {
    await createHome(HOME, OWNER);
    await createUser(JOINER, {
      nickname: 'Code Carlos',
      phone: '+34611222333',
      phoneVisibility: 'sameHomeMembers',
    });
    await getDb().collection('homes').doc(HOME).collection('invitations').doc(INV).set({
      code: CODE, used: false, expiresAt: futureTs(),
    });
  });

  it('el miembro creado por código hereda el teléfono visible', async () => {
    await wrappedJoinByCode(makeCallableRequest(JOINER, { code: CODE }));

    const member = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(JOINER).get();
    expect(member.data()!['phone']).toBe('+34611222333');
    expect(member.data()!['phoneVisibility']).toBe('sameHomeMembers');
  });
});

describe('syncMemberProfile — re-sincroniza teléfono al editar el perfil', () => {
  const HOME = 'home-sync-phone';
  const UID = 'user-edits-phone';

  beforeAll(async () => {
    await createHome(HOME, OWNER);
    // Miembro ya existente con teléfono oculto (estado previo al fix).
    await addMemberToHome(HOME, UID, 'member', 'active', {
      nickname: 'Edita Elena',
      phone: null,
      phoneVisibility: 'hidden',
    });
  });

  it('al activar la visibilidad y añadir teléfono, el doc de miembro se actualiza', async () => {
    await runSyncTrigger(
      UID,
      { nickname: 'Edita Elena', phone: null, phoneVisibility: 'hidden' },
      { nickname: 'Edita Elena', phone: '+34622333444', phoneVisibility: 'sameHomeMembers' },
    );

    const member = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(UID).get();
    expect(member.data()!['phone']).toBe('+34622333444');
    expect(member.data()!['phoneVisibility']).toBe('sameHomeMembers');
  });

  it('al ocultar de nuevo el teléfono, el doc de miembro deja de exponerlo', async () => {
    await runSyncTrigger(
      UID,
      { nickname: 'Edita Elena', phone: '+34622333444', phoneVisibility: 'sameHomeMembers' },
      { nickname: 'Edita Elena', phone: '+34622333444', phoneVisibility: 'hidden' },
    );

    const member = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(UID).get();
    expect(member.data()!['phoneVisibility']).toBe('hidden');
    // PRIVACIDAD (Hallazgo #01): el número se BORRA del doc de miembro (legible
    // por todo el hogar) en cuanto se oculta. Antes se conservaba y solo se
    // filtraba en cliente (phoneForViewer), por lo que cualquier co-miembro lo
    // leía en claro. El usuario sigue viéndolo desde su perfil users/{uid}.
    expect(member.data()!['phone']).toBeNull();
  });
});
