// functions/test/integration/homes_governance.test.ts
//
// Hallazgo #12 — Gobernanza de roles. Ejercita las callables REALES
// (removeMember / promoteToAdmin / transferOwnership / leaveHome) contra el
// emulador de Firestore, en vez de "tests espejo" que reimplementan la lógica.
//
// Cubre:
//   1. removeMember: SOLO el owner puede expulsar (antes un admin expulsaba
//      unilateralmente a cualquier member; la UI ya lo ocultaba a no-owners
//      pero la callable lo permitía → escalada vía llamada directa).
//   2. promoteToAdmin: tope de administradores (antes no había ninguno).
//   3. transferOwnership + leaveHome: salida limpia del owner (el owner no
//      puede abandonar directamente; transfiere y entonces sí puede salir).

import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import {
  removeMember,
  promoteToAdmin,
  transferOwnership,
  leaveHome,
} from '../../src/homes/index';

const runRemove = (req: any): Promise<any> => (removeMember as any).run(req);
const runPromote = (req: any): Promise<any> => (promoteToAdmin as any).run(req);
const runTransfer = (req: any): Promise<any> => (transferOwnership as any).run(req);
const runLeave = (req: any): Promise<any> => (leaveHome as any).run(req);

function memberStatus(homeId: string, uid: string): Promise<string | undefined> {
  return getDb()
    .collection('homes').doc(homeId)
    .collection('members').doc(uid)
    .get()
    .then((d) => d.data()?.['status'] as string | undefined);
}

function memberRole(homeId: string, uid: string): Promise<string | undefined> {
  return getDb()
    .collection('homes').doc(homeId)
    .collection('members').doc(uid)
    .get()
    .then((d) => d.data()?.['role'] as string | undefined);
}

// ---------------------------------------------------------------------------
describe('removeMember — solo el owner puede expulsar', () => {
  const HOME = 'gov-rm';
  const OWNER = 'gov-rm-owner';
  const ADMIN = 'gov-rm-admin';
  const MEMBER = 'gov-rm-member';
  const MEMBER2 = 'gov-rm-member2';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(ADMIN);
    await createUser(MEMBER);
    await createUser(MEMBER2);
    await createHome(HOME, OWNER); // añade OWNER como owner
    await addMemberToHome(HOME, ADMIN, 'admin', 'active');
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await addMemberToHome(HOME, MEMBER2, 'member', 'active');
  });

  it('el owner puede expulsar a un member (status → left)', async () => {
    await runRemove(makeCallableRequest(OWNER, { homeId: HOME, targetUid: MEMBER }));
    expect(await memberStatus(HOME, MEMBER)).toBe('left');
  });

  it('un admin NO puede expulsar a un member (permission-denied) y el member sigue dentro', async () => {
    await expect(
      runRemove(makeCallableRequest(ADMIN, { homeId: HOME, targetUid: MEMBER2 }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
    expect(await memberStatus(HOME, MEMBER2)).toBe('active');
  });

  it('nadie puede expulsar al owner', async () => {
    await expect(
      runRemove(makeCallableRequest(ADMIN, { homeId: HOME, targetUid: OWNER }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberStatus(HOME, OWNER)).toBe('active');
  });

  it('un member no puede expulsar a nadie', async () => {
    await expect(
      runRemove(makeCallableRequest(MEMBER, { homeId: HOME, targetUid: MEMBER2 }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});

// ---------------------------------------------------------------------------
describe('promoteToAdmin — tope de administradores', () => {
  const HOME = 'gov-cap';
  const OWNER = 'gov-cap-owner';
  // 6 candidatos a admin: caben 5, el 6º debe ser rechazado.
  const CANDS = Array.from({ length: 6 }, (_, i) => `gov-cap-u${i + 1}`);

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    // Hogar Premium: si fuera Free, promoteToAdmin se bloquea antes por el gate
    // free (FREE_LIMIT_CODES.admins). Queremos probar el tope Premium.
    await createHome(HOME, OWNER, { premiumStatus: 'active' });
    for (const uid of CANDS) {
      await createUser(uid);
      await addMemberToHome(HOME, uid, 'member', 'active');
    }
  });

  it('promueve hasta 5 admins; el 6º falla con resource-exhausted', async () => {
    for (let i = 0; i < 5; i++) {
      await runPromote(makeCallableRequest(OWNER, { homeId: HOME, targetUid: CANDS[i] }));
      expect(await memberRole(HOME, CANDS[i])).toBe('admin');
    }
    await expect(
      runPromote(makeCallableRequest(OWNER, { homeId: HOME, targetUid: CANDS[5] }))
    ).rejects.toMatchObject({ code: 'resource-exhausted' });
    // El 6º sigue siendo member.
    expect(await memberRole(HOME, CANDS[5])).toBe('member');
  });

  it('un admin expulsado (left) no cuenta para el tope', async () => {
    // Promovemos 5 y expulsamos a uno → debe poder promoverse otro.
    for (let i = 0; i < 5; i++) {
      await runPromote(makeCallableRequest(OWNER, { homeId: HOME, targetUid: CANDS[i] }));
    }
    // El owner expulsa a un admin (owner sí puede). Su rol queda 'admin' pero
    // status 'left' → no debe contar.
    await runRemove(makeCallableRequest(OWNER, { homeId: HOME, targetUid: CANDS[0] }));
    expect(await memberStatus(HOME, CANDS[0])).toBe('left');
    // Ahora hay 4 admins activos → el 6º candidato sí puede promoverse.
    await runPromote(makeCallableRequest(OWNER, { homeId: HOME, targetUid: CANDS[5] }));
    expect(await memberRole(HOME, CANDS[5])).toBe('admin');
  });
});

// ---------------------------------------------------------------------------
describe('transferOwnership + leaveHome — salida limpia del owner', () => {
  const HOME = 'gov-tl';
  const OWNER = 'gov-tl-owner';
  const NEW = 'gov-tl-new';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(NEW);
    await createHome(HOME, OWNER); // Free → sin payer-lock
    await addMemberToHome(HOME, NEW, 'member', 'active');
  });

  it('el owner NO puede abandonar directamente', async () => {
    await expect(
      runLeave(makeCallableRequest(OWNER, { homeId: HOME }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberStatus(HOME, OWNER)).toBe('active');
  });

  it('tras transferir, el ex-owner queda admin y puede salir; el nuevo es owner', async () => {
    await runTransfer(
      makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: NEW })
    );
    const home = await getDb().collection('homes').doc(HOME).get();
    expect(home.data()!['ownerUid']).toBe(NEW);
    expect(await memberRole(HOME, NEW)).toBe('owner');
    expect(await memberRole(HOME, OWNER)).toBe('admin');

    // El ex-owner (ahora admin) ya puede abandonar.
    await runLeave(makeCallableRequest(OWNER, { homeId: HOME }));
    expect(await memberStatus(HOME, OWNER)).toBe('left');
    // El nuevo owner sigue activo.
    expect(await memberStatus(HOME, NEW)).toBe('active');
  });
});

// ---------------------------------------------------------------------------
// Hallazgo #20: edge cases adicionales contra las callables REALES. Sustituyen
// a los "tests espejo" de homes_callables.test.ts (canReceiveOwnership /
// canLeave / isPayerLocked / validate*Input), que reimplementaban estas reglas
// en el propio test en vez de ejercitar la callable.
describe('transferOwnership — estado del nuevo owner y validación de entrada', () => {
  const HOME = 'gov-to-edge';
  const OWNER = 'gov-toe-owner';
  const MEMBER = 'gov-toe-member';
  const FROZEN = 'gov-toe-frozen';
  const LEFTM = 'gov-toe-left';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(MEMBER);
    await createUser(FROZEN);
    await createUser(LEFTM);
    await createHome(HOME, OWNER); // Free → sin payer-lock
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
    await addMemberToHome(HOME, LEFTM, 'member', 'left');
  });

  it('un miembro frozen SÍ puede recibir la propiedad (Caso D)', async () => {
    await runTransfer(makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: FROZEN }));
    expect(await memberRole(HOME, FROZEN)).toBe('owner');
    expect(await memberRole(HOME, OWNER)).toBe('admin');
  });

  it('un ex-miembro (left) NO puede recibir la propiedad → failed-precondition', async () => {
    await expect(
      runTransfer(makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: LEFTM }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberRole(HOME, OWNER)).toBe('owner'); // sin cambios
  });

  it('transferir a un no-miembro → not-found', async () => {
    await createUser('gov-toe-outsider');
    await expect(
      runTransfer(makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: 'gov-toe-outsider' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('transferirse a uno mismo → invalid-argument', async () => {
    await expect(
      runTransfer(makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: OWNER }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('newOwnerUid vacío → invalid-argument', async () => {
    await expect(
      runTransfer(makeCallableRequest(OWNER, { homeId: HOME, newOwnerUid: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('un no-owner no puede transferir → permission-denied', async () => {
    await expect(
      runTransfer(makeCallableRequest(MEMBER, { homeId: HOME, newOwnerUid: FROZEN }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('removeMember — auto-expulsión, entrada y protección del pagador', () => {
  const HOME = 'gov-rm-edge';
  const OWNER = 'gov-rme-owner';
  const PAYER = 'gov-rme-payer';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(PAYER);
  });

  it('no puedes expulsarte a ti mismo (usa leaveHome) → failed-precondition', async () => {
    await createHome(HOME, OWNER);
    await expect(
      runRemove(makeCallableRequest(OWNER, { homeId: HOME, targetUid: OWNER }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('targetUid vacío → invalid-argument', async () => {
    await expect(
      runRemove(makeCallableRequest(OWNER, { homeId: HOME, targetUid: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('el pagador (no-owner) está protegido mientras el Premium esté activo', async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'active', currentPayerUid: PAYER });
    await addMemberToHome(HOME, PAYER, 'member', 'active');
    await expect(
      runRemove(makeCallableRequest(OWNER, { homeId: HOME, targetUid: PAYER }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberStatus(HOME, PAYER)).toBe('active'); // sigue dentro
  });
});

describe('leaveHome — miembro normal y protección del pagador', () => {
  const HOME = 'gov-lv-edge';
  const OWNER = 'gov-lve-owner';
  const MEMBER = 'gov-lve-member';
  const PAYER = 'gov-lve-payer';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(MEMBER);
    await createUser(PAYER);
  });

  it('un miembro normal puede abandonar (status → left)', async () => {
    await createHome(HOME, OWNER);
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await runLeave(makeCallableRequest(MEMBER, { homeId: HOME }));
    expect(await memberStatus(HOME, MEMBER)).toBe('left');
  });

  it('el pagador no puede abandonar mientras el Premium esté activo → failed-precondition', async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'active', currentPayerUid: PAYER });
    await addMemberToHome(HOME, PAYER, 'member', 'active');
    await expect(
      runLeave(makeCallableRequest(PAYER, { homeId: HOME }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await memberStatus(HOME, PAYER)).toBe('active');
  });
});
