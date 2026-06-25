// functions/test/integration/plus_member_backfill.test.ts
//
// Backfill de la proyección `plusActive` en homes/{homeId}/members/{uid} cuando
// se crea/reactiva un doc de miembro (crear hogar, unirse por código, reincorporar).
// Cubre el hueco de "el usuario ya tenía Plus ANTES de entrar a este hogar": sin
// esto, su plusActive quedaría ausente (false) hasta el siguiente cambio de Plus.

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, getDb, makeCallableRequest,
} from './helpers/setup';
import {
  createHome as createHomeFn,
  joinHomeByCode,
  reinstateMember,
} from '../../src/homes/index';
import { applyPlusEntitlement } from '../../src/entitlement/plus_entitlement';

const runCreate = (req: any): Promise<any> => (createHomeFn as any).run(req);
const runJoinByCode = (req: any): Promise<any> => (joinHomeByCode as any).run(req);
const runReinstate = (req: any): Promise<any> => (reinstateMember as any).run(req);

function futureTs() {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 3600 * 1000));
}

async function giveActivePlus(uid: string): Promise<void> {
  // Antes de tener memberships → propagatePlusActiveToMembers es no-op, así que
  // el plusActive de los docs de miembro solo lo puede poner el backfill de alta.
  await applyPlusEntitlement(getDb(), {
    uid, status: 'active', cycle: 'monthly',
    endsAt: new Date(Date.now() + 31 * 24 * 3600 * 1000), autoRenewEnabled: true,
    productId: 'toka_plus_monthly', platform: 'android',
    chargeId: 'backfill-' + uid, source: 'purchase',
  });
}

function memberDoc(homeId: string, uid: string) {
  return getDb().collection('homes').doc(homeId).collection('members').doc(uid).get();
}

beforeAll(async () => {
  await cleanAll();
});

describe('createHome (callable) — backfill plusActive del owner', () => {
  it('owner con Plus activo → su member doc nace con plusActive=true', async () => {
    const OWNER = 'bf-create-owner-plus';
    await createUser(OWNER);
    await giveActivePlus(OWNER);
    const res = await runCreate(makeCallableRequest(OWNER, { name: 'Casa Plus' }));
    const m = await memberDoc(res.homeId, OWNER);
    expect(m.data()!['plusActive']).toBe(true);
  });

  it('owner sin Plus → plusActive=false por defecto', async () => {
    const OWNER = 'bf-create-owner-free';
    await createUser(OWNER);
    const res = await runCreate(makeCallableRequest(OWNER, { name: 'Casa Free' }));
    const m = await memberDoc(res.homeId, OWNER);
    expect(m.data()!['plusActive']).toBe(false);
  });
});

describe('joinHomeByCode — backfill plusActive del que se une', () => {
  const HOME = 'bf-join-home';
  const HOST = 'bf-join-host';

  beforeAll(async () => {
    await createHome(HOME, HOST);
  });

  it('joiner con Plus activo → member doc con plusActive=true', async () => {
    const JOINER = 'bf-joiner-plus';
    await createUser(JOINER);
    await giveActivePlus(JOINER);
    await getDb().collection('homes').doc(HOME).collection('invitations').doc('inv-plus').set({
      code: 'PLUSJOIN', used: false, expiresAt: futureTs(),
    });
    await runJoinByCode(makeCallableRequest(JOINER, { code: 'PLUSJOIN' }));
    const m = await memberDoc(HOME, JOINER);
    expect(m.data()!['plusActive']).toBe(true);
  });

  it('joiner sin Plus → plusActive=false', async () => {
    const JOINER = 'bf-joiner-free';
    await createUser(JOINER);
    await getDb().collection('homes').doc(HOME).collection('invitations').doc('inv-free').set({
      code: 'FREEJOIN', used: false, expiresAt: futureTs(),
    });
    await runJoinByCode(makeCallableRequest(JOINER, { code: 'FREEJOIN' }));
    const m = await memberDoc(HOME, JOINER);
    expect(m.data()!['plusActive']).toBe(false);
  });
});

describe('reinstateMember — backfill plusActive al reincorporar', () => {
  it('target con Plus reincorporado → plusActive=true', async () => {
    const HOME = 'bf-reinstate-home';
    const OWNER = 'bf-reinstate-owner';
    const TARGET = 'bf-reinstate-target';
    await createUser(TARGET);
    await giveActivePlus(TARGET); // sin memberships aún → no-op de propagación
    await createHome(HOME, OWNER);
    // Miembro que dejó el hogar (member doc status 'left', sin plusActive).
    await addMemberToHome(HOME, TARGET, 'member', 'left');
    const beforeDoc = await memberDoc(HOME, TARGET);
    expect(beforeDoc.data()!['plusActive']).toBeUndefined();

    await runReinstate(makeCallableRequest(OWNER, { homeId: HOME, targetUid: TARGET }));
    const m = await memberDoc(HOME, TARGET);
    expect(m.data()!['status']).toBe('active');
    expect(m.data()!['plusActive']).toBe(true);
  });
});
