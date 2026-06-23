// functions/test/integration/sent_notifications_purge.test.ts
//
// Hallazgo #17: homes/{id}/sentNotifications crecía sin TTL (solo se usan para
// deduplicar envíos dentro de su bucket de 15 min). El cron purgeExpiredFrozen
// ahora también borra los docs antiguos (sentAt anterior al TTL), conservando
// los recientes y SIN romper su función original (purgar hogares 'restorable').

import * as admin from 'firebase-admin';
import { cleanAll, createHome, getDb } from './helpers/setup';
import { purgeExpiredFrozen } from '../../src/jobs/purge_expired_frozen';

const run = (): Promise<any> => (purgeExpiredFrozen as any).run({});

function daysAgo(d: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Date.now() - d * 24 * 60 * 60 * 1000);
}
function daysFromNow(d: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Date.now() + d * 24 * 60 * 60 * 1000);
}

const HOME = 'home-sent-purge';
const HOME_RESTORABLE = 'home-restorable';
const HOME_FUTURE = 'home-future-restore';

async function sentDoc(id: string, fields: Record<string, unknown>): Promise<void> {
  await getDb().collection('homes').doc(HOME).collection('sentNotifications').doc(id).set(fields);
}
async function sentExists(id: string): Promise<boolean> {
  const s = await getDb().collection('homes').doc(HOME).collection('sentNotifications').doc(id).get();
  return s.exists;
}

beforeAll(async () => {
  await cleanAll();
  await createHome(HOME, 'owner-sp');

  // Antiguo con expireAt + sentAt → debe borrarse.
  await sentDoc('old-with-expire', { sentAt: daysAgo(3), expireAt: daysAgo(1) });
  // Antiguo "legacy" sin expireAt (doc creado antes del cambio) → debe borrarse
  // por el fallback de sentAt.
  await sentDoc('old-legacy', { sentAt: daysAgo(5) });
  // Reciente → debe conservarse.
  await sentDoc('fresh', { sentAt: admin.firestore.Timestamp.now(), expireAt: daysFromNow(2) });

  // Función original del cron: hogar 'restorable' vencido → 'purged'; no vencido
  // → se conserva.
  await createHome(HOME_RESTORABLE, 'owner-r', {
    premiumStatus: 'restorable',
    restoreUntil: daysAgo(1),
  });
  await createHome(HOME_FUTURE, 'owner-f', {
    premiumStatus: 'restorable',
    restoreUntil: daysFromNow(10),
  });

  await run();
});

describe('purgeExpiredFrozen — purga de sentNotifications (Hallazgo #17)', () => {
  it('borra los docs antiguos (con y sin expireAt)', async () => {
    expect(await sentExists('old-with-expire')).toBe(false);
    expect(await sentExists('old-legacy')).toBe(false);
  });

  it('conserva los docs recientes', async () => {
    expect(await sentExists('fresh')).toBe(true);
  });
});

describe('purgeExpiredFrozen — función original intacta', () => {
  it('hogar restorable vencido → purged', async () => {
    const s = await getDb().collection('homes').doc(HOME_RESTORABLE).get();
    expect(s.data()?.['premiumStatus']).toBe('purged');
  });

  it('hogar restorable no vencido → se conserva restorable', async () => {
    const s = await getDb().collection('homes').doc(HOME_FUTURE).get();
    expect(s.data()?.['premiumStatus']).toBe('restorable');
  });
});
