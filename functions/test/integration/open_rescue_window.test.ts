// functions/test/integration/open_rescue_window.test.ts
//
// openRescueWindow es un scheduled job (onSchedule).
// Lo testeamos llamando directamente al handler exportado.
// Usamos firebase-functions-test para hacer wrap del scheduled handler.

import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import { cleanAll, createUser, createHome, getDb } from './helpers/setup';
import { openRescueWindow } from '../../src/entitlement/open_rescue_window';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(openRescueWindow) as (req: any) => Promise<any>;

const HOME_NEAR = 'home-rescue-near';    // premiumEndsAt dentro de 2 días
const HOME_FAR = 'home-rescue-far';     // premiumEndsAt dentro de 10 días
const HOME_ALREADY = 'home-rescue-done'; // ya está en rescue
const OWNER = 'owner-rescue';

function daysFromNow(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + days * 24 * 60 * 60 * 1000));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);

  // HOME_NEAR: premiumStatus=cancelled_pending_end, endsAt en 2 días
  await createHome(HOME_NEAR, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(2),
  });

  // HOME_FAR: premiumStatus=cancelled_pending_end, endsAt en 10 días (fuera de ventana)
  await createHome(HOME_FAR, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(10),
  });

  // HOME_ALREADY: ya está en rescue
  await createHome(HOME_ALREADY, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(1),
    rescueFlags: { isInRescue: true },
  });
});

afterAll(() => testEnv.cleanup());

describe('openRescueWindow — scheduled job', () => {
  it('hogar dentro de ventana de 3 días → premiumStatus cambia a rescue', async () => {
    await wrapped({}); // scheduled jobs no necesitan auth

    const homeDoc = await getDb().collection('homes').doc(HOME_NEAR).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('rescue');
  });

  it('hogar dentro de ventana → dashboard tiene rescueFlags.isInRescue = true', async () => {
    const dashDoc = await getDb().collection('homes').doc(HOME_NEAR).collection('views').doc('dashboard').get();
    expect(dashDoc.data()?.['rescueFlags']?.['isInRescue']).toBe(true);
    expect(dashDoc.data()?.['rescueFlags']?.['daysLeft']).toBeGreaterThanOrEqual(0);
  });

  it('hogar fuera de ventana de 3 días → NO cambia a rescue', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_FAR).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('cancelled_pending_end');
  });

  it('hogar ya en rescue → NO se vuelve a procesar', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_ALREADY).get();
    // premiumStatus sigue siendo cancelled_pending_end (no se procesó porque isInRescue=true)
    expect(homeDoc.data()!['premiumStatus']).toBe('cancelled_pending_end');
  });
});
