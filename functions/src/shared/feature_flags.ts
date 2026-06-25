// functions/src/shared/feature_flags.ts
//
// Lectura SERVER-SIDE de flags de Firebase Remote Config desde Cloud Functions.
//
// El backend es la fuente de verdad del tope de miembros por tier, así que el
// flag que activa el modelo de tiers (`home_tiers_enabled`) debe consultarse en
// el servidor. Se lee con el Admin SDK (`getServerTemplate().evaluate()`),
// cacheado con un TTL corto para no pegar a Remote Config en cada operación, y
// con un fallback SEGURO a OFF ante cualquier error (así el comportamiento por
// defecto es el binario actual aunque RC no esté disponible).
//
// La IO (la llamada a Remote Config) y el reloj están inyectados para poder
// testear caché y fallback sin red ni emulador de RC. En tests de integración se
// fija el valor con `__setHomeTiersEnabledForTesting`.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/** Nombre del parámetro booleano en Firebase Remote Config. */
export const HOME_TIERS_FLAG = "home_tiers_enabled";

/**
 * Nombre del parámetro booleano que activa el eje de entitlement individual
 * "Toka Plus". Con el flag OFF, ningún usuario tiene Plus activo aunque el doc
 * `users/{uid}/entitlements/plus` exista (el gating se aplica al consumir, ver
 * `isPlusEffectivelyActive` en `entitlement/plus_catalog.ts`). Debe coincidir
 * con `RemoteConfigService.tokaPlusEnabled` del cliente.
 */
export const TOKA_PLUS_FLAG = "toka_plus_enabled";

/**
 * Nombre del parámetro booleano que activa los PACKS DE MIEMBRO (eje aditivo que
 * amplía el tope de un hogar Grupo con plazas extra). Independiente de
 * `home_tiers_enabled`: con este flag OFF, el tope máximo vuelve al del tier
 * (Grupo 10) sin packs, aunque el hogar tenga packs registrados. El gating se
 * aplica al computar el tope (`resolveEntitlement`/`effectiveMaxMembers`). Debe
 * coincidir con `RemoteConfigService.memberPacksEnabled` del cliente.
 */
export const MEMBER_PACKS_FLAG = "member_packs_enabled";

/** Ventana de caché del valor del flag (5 min). */
export const FLAG_CACHE_TTL_MS = 5 * 60 * 1000;

type Fetcher = () => Promise<boolean>;

/**
 * Fetcher real: lee el parámetro booleano de Remote Config (server template)
 * con default OFF embebido. Aislado para poder inyectar un fake en tests.
 */
async function defaultRemoteConfigFetcher(): Promise<boolean> {
  const template = await admin.remoteConfig().getServerTemplate({
    defaultConfig: { [HOME_TIERS_FLAG]: false },
  });
  const config = template.evaluate();
  return config.getBoolean(HOME_TIERS_FLAG);
}

/** Fetcher real del flag de Toka Plus (server template, default OFF). */
async function defaultPlusFetcher(): Promise<boolean> {
  const template = await admin.remoteConfig().getServerTemplate({
    defaultConfig: { [TOKA_PLUS_FLAG]: false },
  });
  const config = template.evaluate();
  return config.getBoolean(TOKA_PLUS_FLAG);
}

/** Fetcher real del flag de packs de miembro (server template, default OFF). */
async function defaultPacksFetcher(): Promise<boolean> {
  const template = await admin.remoteConfig().getServerTemplate({
    defaultConfig: { [MEMBER_PACKS_FLAG]: false },
  });
  const config = template.evaluate();
  return config.getBoolean(MEMBER_PACKS_FLAG);
}

let _override: boolean | undefined;
let _fetcher: Fetcher = defaultRemoteConfigFetcher;
let _cache: { value: boolean; at: number } | null = null;

/**
 * Devuelve si el modelo de tiers por tamaño de hogar está activo.
 * Cacheado (TTL) y con fallback a OFF si Remote Config falla.
 *
 * @param nowMs reloj inyectable para tests (por defecto Date.now()).
 */
export async function isHomeTiersEnabled(
  nowMs: number = Date.now(),
): Promise<boolean> {
  if (_override !== undefined) return _override;
  if (_cache && nowMs - _cache.at < FLAG_CACHE_TTL_MS) return _cache.value;
  try {
    const value = await _fetcher();
    _cache = { value, at: nowMs };
    return value;
  } catch (err) {
    logger.error(
      "isHomeTiersEnabled: lectura de Remote Config falló; default OFF",
      err,
    );
    return false;
  }
}

/**
 * Seam SOLO para tests: fija el valor del flag (o `undefined` para restaurar la
 * lectura real). Invalida la caché.
 */
export function __setHomeTiersEnabledForTesting(v: boolean | undefined): void {
  _override = v;
  _cache = null;
}

/**
 * Seam SOLO para tests: inyecta un fetcher fake (o `undefined` para restaurar
 * el real). Invalida la caché.
 */
export function __setTiersFetcherForTesting(f: Fetcher | undefined): void {
  _fetcher = f ?? defaultRemoteConfigFetcher;
  _cache = null;
}

// ---------------------------------------------------------------------------
// Toka Plus — flag de Remote Config del eje de entitlement individual.
// Estado de módulo independiente del de tiers (override/fetcher/caché propios)
// para que ambos flags se cacheen y testeen por separado.
// ---------------------------------------------------------------------------

let _plusOverride: boolean | undefined;
let _plusFetcher: Fetcher = defaultPlusFetcher;
let _plusCache: { value: boolean; at: number } | null = null;

/**
 * Devuelve si el eje de entitlement "Toka Plus" está activo. Cacheado (TTL) y
 * con fallback a OFF si Remote Config falla (comportamiento por defecto: Plus
 * inexistente). El gating efectivo per-usuario se hace con este valor al
 * consumir (`isPlusEffectivelyActive`).
 *
 * @param nowMs reloj inyectable para tests (por defecto Date.now()).
 */
export async function isTokaPlusEnabled(
  nowMs: number = Date.now(),
): Promise<boolean> {
  if (_plusOverride !== undefined) return _plusOverride;
  if (_plusCache && nowMs - _plusCache.at < FLAG_CACHE_TTL_MS) {
    return _plusCache.value;
  }
  try {
    const value = await _plusFetcher();
    _plusCache = { value, at: nowMs };
    return value;
  } catch (err) {
    logger.error(
      "isTokaPlusEnabled: lectura de Remote Config falló; default OFF",
      err,
    );
    return false;
  }
}

/** Seam SOLO para tests: fija el valor del flag de Plus (undefined → real). */
export function __setTokaPlusEnabledForTesting(v: boolean | undefined): void {
  _plusOverride = v;
  _plusCache = null;
}

/** Seam SOLO para tests: inyecta un fetcher fake del flag de Plus. */
export function __setPlusFetcherForTesting(f: Fetcher | undefined): void {
  _plusFetcher = f ?? defaultPlusFetcher;
  _plusCache = null;
}

// ---------------------------------------------------------------------------
// Member packs — flag de Remote Config del eje aditivo de plazas.
// Estado de módulo independiente del de tiers/Plus (override/fetcher/caché
// propios) para que los tres flags se cacheen y testeen por separado.
// ---------------------------------------------------------------------------

let _packsOverride: boolean | undefined;
let _packsFetcher: Fetcher = defaultPacksFetcher;
let _packsCache: { value: boolean; at: number } | null = null;

/**
 * Devuelve si los packs de miembro están activos. Cacheado (TTL) y con fallback
 * a OFF si Remote Config falla (comportamiento por defecto: tope del tier sin
 * packs). El gating efectivo del tope se hace con este valor al computar
 * `resolveEntitlement`/`effectiveMaxMembers`.
 *
 * @param nowMs reloj inyectable para tests (por defecto Date.now()).
 */
export async function isMemberPacksEnabled(
  nowMs: number = Date.now(),
): Promise<boolean> {
  if (_packsOverride !== undefined) return _packsOverride;
  if (_packsCache && nowMs - _packsCache.at < FLAG_CACHE_TTL_MS) {
    return _packsCache.value;
  }
  try {
    const value = await _packsFetcher();
    _packsCache = { value, at: nowMs };
    return value;
  } catch (err) {
    logger.error(
      "isMemberPacksEnabled: lectura de Remote Config falló; default OFF",
      err,
    );
    return false;
  }
}

/** Seam SOLO para tests: fija el valor del flag de packs (undefined → real). */
export function __setMemberPacksEnabledForTesting(v: boolean | undefined): void {
  _packsOverride = v;
  _packsCache = null;
}

/** Seam SOLO para tests: inyecta un fetcher fake del flag de packs. */
export function __setPacksFetcherForTesting(f: Fetcher | undefined): void {
  _packsFetcher = f ?? defaultPacksFetcher;
  _packsCache = null;
}
