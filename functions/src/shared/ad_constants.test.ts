import {
  TEST_BANNER_UNIT_ID_ANDROID,
  TEST_BANNER_UNIT_ID_IOS,
  isTestAdUnit,
  resolveBannerUnits,
  buildBannerAdFlags,
  assertReleaseAdUnits,
} from "./ad_constants";

const REAL_ANDROID = "ca-app-pub-1111111111111111/2222222222";
const REAL_IOS = "ca-app-pub-1111111111111111/3333333333";

const releaseEnv = {
  ADMOB_BANNER_UNIT_ANDROID: REAL_ANDROID,
  ADMOB_BANNER_UNIT_IOS: REAL_IOS,
} as NodeJS.ProcessEnv;

describe("isTestAdUnit", () => {
  it("detecta los unit IDs de prueba de Google", () => {
    expect(isTestAdUnit(TEST_BANNER_UNIT_ID_ANDROID)).toBe(true);
    expect(isTestAdUnit(TEST_BANNER_UNIT_ID_IOS)).toBe(true);
  });

  it("NO marca como prueba un unit real", () => {
    expect(isTestAdUnit(REAL_ANDROID)).toBe(false);
    expect(isTestAdUnit("")).toBe(false);
    expect(isTestAdUnit(undefined)).toBe(false);
  });
});

describe("resolveBannerUnits", () => {
  it("usa los unit IDs reales del entorno por plataforma", () => {
    const units = resolveBannerUnits(releaseEnv);
    expect(units.android).toBe(REAL_ANDROID);
    expect(units.ios).toBe(REAL_IOS);
  });

  it("recorta espacios del entorno", () => {
    const units = resolveBannerUnits({
      ADMOB_BANNER_UNIT_ANDROID: `  ${REAL_ANDROID}  `,
      ADMOB_BANNER_UNIT_IOS: `\t${REAL_IOS}\n`,
    } as NodeJS.ProcessEnv);
    expect(units.android).toBe(REAL_ANDROID);
    expect(units.ios).toBe(REAL_IOS);
  });

  it("cae a los IDs de prueba como fallback de dev cuando no hay env", () => {
    const units = resolveBannerUnits({} as NodeJS.ProcessEnv);
    expect(units.android).toBe(TEST_BANNER_UNIT_ID_ANDROID);
    expect(units.ios).toBe(TEST_BANNER_UNIT_ID_IOS);
  });
});

describe("buildBannerAdFlags", () => {
  it("hogar Premium (showBanner=false) → units vacíos, sin banner", () => {
    const flags = buildBannerAdFlags(false, releaseEnv);
    expect(flags.showBanner).toBe(false);
    expect(flags.bannerUnit).toBe("");
    expect(flags.bannerUnitAndroid).toBe("");
    expect(flags.bannerUnitIos).toBe("");
  });

  it("hogar Free con env real → inyecta units reales por plataforma", () => {
    const flags = buildBannerAdFlags(true, releaseEnv);
    expect(flags.showBanner).toBe(true);
    expect(flags.bannerUnitAndroid).toBe(REAL_ANDROID);
    expect(flags.bannerUnitIos).toBe(REAL_IOS);
    // back-compat: clientes viejos leen bannerUnit (= Android)
    expect(flags.bannerUnit).toBe(REAL_ANDROID);
    expect(isTestAdUnit(flags.bannerUnitAndroid)).toBe(false);
    expect(isTestAdUnit(flags.bannerUnitIos)).toBe(false);
  });

  it("hogar Free sin env → test IDs (solo dev)", () => {
    const flags = buildBannerAdFlags(true, {} as NodeJS.ProcessEnv);
    expect(flags.bannerUnitAndroid).toBe(TEST_BANNER_UNIT_ID_ANDROID);
    expect(flags.bannerUnitIos).toBe(TEST_BANNER_UNIT_ID_IOS);
  });
});

describe("assertReleaseAdUnits (guardrail de release)", () => {
  it("FALLA si en configuración de release el banner unit es un ID de prueba", () => {
    // Sin env configurado, resolveBannerUnits cae a los IDs de prueba.
    const units = resolveBannerUnits({} as NodeJS.ProcessEnv);
    expect(() => assertReleaseAdUnits(units)).toThrow(/prueba/i);
  });

  it("FALLA si solo una plataforma sigue con ID de prueba", () => {
    const units = resolveBannerUnits({
      ADMOB_BANNER_UNIT_ANDROID: REAL_ANDROID,
      // iOS sin configurar → fallback de prueba
    } as NodeJS.ProcessEnv);
    expect(() => assertReleaseAdUnits(units)).toThrow(/iOS/);
  });

  it("NO falla cuando ambos units son reales", () => {
    const units = resolveBannerUnits(releaseEnv);
    expect(() => assertReleaseAdUnits(units)).not.toThrow();
  });
});
