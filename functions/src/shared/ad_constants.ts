// AdMob banner ad unit IDs.
//
// Los unit IDs REALES de producción se inyectan por ENTORNO (no son secretos:
// van embebidos en el binario cliente, pero los parametrizamos para no
// hardcodear los IDs de prueba en release). Se setean en
// functions/.env.<projectId> (igual que el resto de config no sensible):
//   ADMOB_BANNER_UNIT_ANDROID  → unit real de Android
//   ADMOB_BANNER_UNIT_IOS      → unit real de iOS
//
// Si NO están configurados, se cae a los IDs de PRUEBA de Google, que son
// seguros en dev (no generan revenue ni infracciones) pero NUNCA deben llegar a
// una release. El guardrail scripts/check-ad-units.js bloquea el deploy de un
// proyecto marcado como release (TOKA_REQUIRE_REAL_AD_UNITS=true) si los units
// resueltos siguen siendo de prueba.

// Test unit IDs oficiales de Google AdMob.
export const TEST_AD_UNIT_PREFIX = "ca-app-pub-3940256099942544";
export const TEST_BANNER_UNIT_ID_ANDROID = "ca-app-pub-3940256099942544/6300978111";
export const TEST_BANNER_UNIT_ID_IOS = "ca-app-pub-3940256099942544/2934735716";

export interface BannerUnits {
  android: string;
  ios: string;
}

export interface BannerAdFlags {
  showBanner: boolean;
  /** Back-compat para clientes viejos que solo leen `bannerUnit` (= Android). */
  bannerUnit: string;
  bannerUnitAndroid: string;
  bannerUnitIos: string;
}

/** true si `unitId` es uno de los IDs de prueba de Google (cero revenue). */
export function isTestAdUnit(unitId: string | undefined | null): boolean {
  return !!unitId && unitId.startsWith(TEST_AD_UNIT_PREFIX);
}

/**
 * Resuelve los banner unit IDs reales por plataforma desde el entorno. Cae a
 * los IDs de PRUEBA solo como fallback de dev cuando no hay nada configurado
 * (mantiene emuladores y dev funcionando sin setup).
 */
export function resolveBannerUnits(env: NodeJS.ProcessEnv = process.env): BannerUnits {
  const android = (env.ADMOB_BANNER_UNIT_ANDROID ?? "").trim();
  const ios = (env.ADMOB_BANNER_UNIT_IOS ?? "").trim();
  return {
    android: android.length > 0 ? android : TEST_BANNER_UNIT_ID_ANDROID,
    ios: ios.length > 0 ? ios : TEST_BANNER_UNIT_ID_IOS,
  };
}

/**
 * Construye el bloque `adFlags` del dashboard. Si el banner no debe mostrarse
 * (hogar Premium) devuelve units vacíos; si debe mostrarse, inyecta los units
 * reales por plataforma resueltos del entorno.
 */
export function buildBannerAdFlags(
  showBanner: boolean,
  env: NodeJS.ProcessEnv = process.env,
): BannerAdFlags {
  if (!showBanner) {
    return { showBanner: false, bannerUnit: "", bannerUnitAndroid: "", bannerUnitIos: "" };
  }
  const units = resolveBannerUnits(env);
  return {
    showBanner: true,
    bannerUnit: units.android,
    bannerUnitAndroid: units.android,
    bannerUnitIos: units.ios,
  };
}

/**
 * Verifica que en una configuración de RELEASE los units resueltos NO sean los
 * de prueba. Lanza si alguno lo es (cero revenue). Lo usan el guardrail de
 * deploy y los tests.
 */
export function assertReleaseAdUnits(units: BannerUnits): void {
  const offenders: string[] = [];
  if (isTestAdUnit(units.android)) offenders.push(`Android (${units.android})`);
  if (isTestAdUnit(units.ios)) offenders.push(`iOS (${units.ios})`);
  if (offenders.length > 0) {
    throw new Error(
      `Banner ad units de PRUEBA en configuración de release: ${offenders.join(", ")}. ` +
        "Configura ADMOB_BANNER_UNIT_ANDROID y ADMOB_BANNER_UNIT_IOS con los unit IDs reales.",
    );
  }
}
