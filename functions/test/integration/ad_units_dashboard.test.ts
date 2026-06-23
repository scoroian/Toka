// functions/test/integration/ad_units_dashboard.test.ts
//
// Integración (premortem #05): el dashboard que escribe el backend lleva los
// banner unit IDs reales POR PLATAFORMA resueltos del entorno, no los de prueba
// hardcodeados. Ejercita el path real de escritura en Firestore (emulador) a
// través de applyDowngradeJob (hogar → Free → buildBannerAdFlags(true)).
import * as admin from 'firebase-admin';
import { cleanAll, createUser, createHome, getDb } from './helpers/setup';
import { applyDowngradeJob } from '../../src/entitlement/apply_downgrade_plan';

const wrapped = (data: any): Promise<any> => (applyDowngradeJob as any).run(data);

const OWNER = 'owner-adunits';
const HOME_REAL = 'home-adunits-real';
const HOME_FALLBACK = 'home-adunits-fallback';

const REAL_ANDROID = 'ca-app-pub-1234567890123456/1111111111';
const REAL_IOS = 'ca-app-pub-1234567890123456/2222222222';
const TEST_PREFIX = 'ca-app-pub-3940256099942544';

function pastDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - days * 24 * 60 * 60 * 1000),
  );
}

async function readAdFlags(homeId: string): Promise<Record<string, unknown>> {
  const snap = await getDb()
    .collection('homes')
    .doc(homeId)
    .collection('views')
    .doc('dashboard')
    .get();
  return (snap.data()?.['adFlags'] ?? {}) as Record<string, unknown>;
}

describe('premortem #05 — dashboard sirve banner units reales por plataforma', () => {
  const prevAndroid = process.env.ADMOB_BANNER_UNIT_ANDROID;
  const prevIos = process.env.ADMOB_BANNER_UNIT_IOS;

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
  });

  afterAll(() => {
    process.env.ADMOB_BANNER_UNIT_ANDROID = prevAndroid;
    process.env.ADMOB_BANNER_UNIT_IOS = prevIos;
  });

  it('con env configurado: adFlags lleva los units reales por plataforma', async () => {
    process.env.ADMOB_BANNER_UNIT_ANDROID = REAL_ANDROID;
    process.env.ADMOB_BANNER_UNIT_IOS = REAL_IOS;

    await createHome(HOME_REAL, OWNER, {
      premiumStatus: 'rescue',
      premiumEndsAt: pastDate(1),
    });

    await wrapped({});

    const adFlags = await readAdFlags(HOME_REAL);
    expect(adFlags['showBanner']).toBe(true);
    expect(adFlags['bannerUnitAndroid']).toBe(REAL_ANDROID);
    expect(adFlags['bannerUnitIos']).toBe(REAL_IOS);
    // back-compat: bannerUnit (legacy) = Android
    expect(adFlags['bannerUnit']).toBe(REAL_ANDROID);
    // y NINGUNO es de prueba
    expect(String(adFlags['bannerUnitAndroid'])).not.toContain(TEST_PREFIX);
    expect(String(adFlags['bannerUnitIos'])).not.toContain(TEST_PREFIX);
  });

  it('sin env (dev): cae a los unit IDs de prueba por plataforma', async () => {
    delete process.env.ADMOB_BANNER_UNIT_ANDROID;
    delete process.env.ADMOB_BANNER_UNIT_IOS;

    await createHome(HOME_FALLBACK, OWNER, {
      premiumStatus: 'rescue',
      premiumEndsAt: pastDate(1),
    });

    await wrapped({});

    const adFlags = await readAdFlags(HOME_FALLBACK);
    expect(adFlags['showBanner']).toBe(true);
    expect(String(adFlags['bannerUnitAndroid'])).toContain(TEST_PREFIX);
    expect(String(adFlags['bannerUnitIos'])).toContain(TEST_PREFIX);
    // Android e iOS son distintos incluso en fallback
    expect(adFlags['bannerUnitAndroid']).not.toBe(adFlags['bannerUnitIos']);
  });
});
