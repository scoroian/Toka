// functions/src/entitlement/sync_entitlement_helpers.ts
import * as logger from "firebase-functions/logger";
import { HttpsError } from "firebase-functions/v2/https";
import {
  verifyGooglePlay,
  verifyAppStore,
  type VerifiedReceipt,
  type GooglePlayConfig,
  type AppStoreConfig,
} from "./store_verifiers";

/**
 * Estructura que devuelve el cliente IAP nativo (in_app_purchase) en
 * `_buildReceiptData`. Solo contiene datos firmables / verificables por las
 * stores — NO contiene fechas ni `status` calculados por el cliente: esos
 * son inferidos server-side tras validar `purchaseToken`.
 */
export interface RawReceipt {
  productId: string;
  purchaseToken: string;
  transactionId: string;
  source: string;
}

/**
 * Resultado de validar un recibo (Google Play / App Store) o, en modo dev,
 * de inferir el plan a partir del productId con un fallback prudente.
 */
export interface ValidatedEntitlement {
  status: string;
  plan: string;
  endsAt: Date | null;
  autoRenewEnabled: boolean;
  /** Identifica si la validación se hizo server-side contra la store real. */
  storeVerified: boolean;
  /**
   * Id de cargo derivado SERVER-SIDE del recibo (purchaseToken en Android,
   * originalTransactionId en iOS). Es la clave de idempotencia: NO se confía
   * en el `chargeId`/`purchaseID` que envía el cliente (puede ser nulo o
   * manipulado).
   */
  chargeId: string;
}

/**
 * Verificadores de recibo por plataforma. Inyectables para poder mockear las
 * APIs de las stores en tests. En producción se construyen desde
 * `buildVerifiersFromEnv()` con las credenciales por env/secret.
 */
export interface ReceiptVerifiers {
  verifyGooglePlay?: (r: RawReceipt) => Promise<VerifiedReceipt>;
  verifyAppStore?: (r: RawReceipt) => Promise<VerifiedReceipt>;
}

// Seam de inyección SOLO para tests de integración (emulador): permite que el
// test instale verificadores mock sin tocar la red. NUNCA se setea en prod.
let _testVerifiers: ReceiptVerifiers | undefined;
export function __setReceiptVerifiersForTesting(
  v: ReceiptVerifiers | undefined,
): void {
  _testVerifiers = v;
}

/**
 * Construye los verificadores reales a partir de las credenciales en env/secret.
 * Si no hay credenciales para una plataforma, su verificador queda `undefined`
 * (en cuyo caso `validateReceipt` rechaza en strict o infiere en dev).
 *
 * Env esperadas:
 *  - Android: GOOGLE_PLAY_PACKAGE_NAME, GOOGLE_PLAY_SA_JSON (JSON de service account)
 *  - iOS: APP_STORE_ISSUER_ID, APP_STORE_KEY_ID, APP_STORE_PRIVATE_KEY,
 *         APP_STORE_BUNDLE_ID, APP_STORE_ENV ("Production"|"Sandbox")
 */
export function buildVerifiersFromEnv(): ReceiptVerifiers {
  const verifiers: ReceiptVerifiers = {};

  const gpPackage = process.env.GOOGLE_PLAY_PACKAGE_NAME;
  const gpCreds = process.env.GOOGLE_PLAY_SA_JSON;
  if (gpPackage && gpCreds) {
    const config: GooglePlayConfig = {
      packageName: gpPackage,
      credentialsJson: gpCreds,
    };
    verifiers.verifyGooglePlay = (r) => verifyGooglePlay(r, config);
  }

  const issuerId = process.env.APP_STORE_ISSUER_ID;
  const keyId = process.env.APP_STORE_KEY_ID;
  const privateKey = process.env.APP_STORE_PRIVATE_KEY;
  const bundleId = process.env.APP_STORE_BUNDLE_ID;
  if (issuerId && keyId && privateKey && bundleId) {
    const config: AppStoreConfig = {
      issuerId,
      keyId,
      // Las claves .p8 suelen guardarse con saltos de línea escapados.
      privateKey: privateKey.replace(/\\n/g, "\n"),
      bundleId,
      environment:
        process.env.APP_STORE_ENV === "Sandbox" ? "Sandbox" : "Production",
    };
    verifiers.verifyAppStore = (r) => verifyAppStore(r, config);
  }

  return verifiers;
}

/**
 * Devuelve los verificadores activos: los inyectados en tests si los hay, o los
 * construidos desde env/secret. Lo usan tanto la callable como los handlers de
 * notificaciones de store (RTDN / App Store) para re-verificar recibos.
 */
export function getActiveVerifiers(): ReceiptVerifiers {
  return _testVerifiers ?? buildVerifiersFromEnv();
}

/**
 * Indica si hay un verificador real (Google Play / App Store) configurado para
 * la plataforma — ya sea por env/secret o inyectado en tests. Lo usa la callable
 * para decidir si puede operar sin el flag de "recibos no verificados".
 */
export function hasConfiguredVerifier(platform: "ios" | "android"): boolean {
  const active = getActiveVerifiers();
  return platform === "android"
    ? !!active.verifyGooglePlay
    : !!active.verifyAppStore;
}

/**
 * Parser estricto del receiptData enviado por el cliente.
 *
 * Antes este helper aceptaba un JSON con `status`, `plan`, `endsAt`,
 * `autoRenewEnabled` calculados por el cliente. Eso era una vulnerabilidad
 * crítica: cualquier usuario autenticado podía enviar `status:"active"` y
 * obtener Premium gratis. Ahora exigimos los datos firmables por las stores.
 */
export function parseReceiptData(receiptData: string): RawReceipt {
  try {
    const parsed = JSON.parse(receiptData) as Partial<RawReceipt>;
    if (
      typeof parsed.productId !== "string" ||
      parsed.productId.length === 0 ||
      typeof parsed.purchaseToken !== "string" ||
      parsed.purchaseToken.length === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Receipt missing productId or purchaseToken",
      );
    }
    return {
      productId: parsed.productId,
      purchaseToken: parsed.purchaseToken,
      transactionId: parsed.transactionId ?? "",
      source: parsed.source ?? "",
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    throw new HttpsError("invalid-argument", "Invalid receipt data format");
  }
}

/**
 * Valida el recibo contra la store correspondiente y devuelve el entitlement
 * real. Si hay un verificador configurado para la plataforma (credenciales en
 * env/secret), SIEMPRE se usa y el estado Premium se deriva del recibo
 * verificado por Google Play / App Store.
 *
 * Si NO hay verificador configurado:
 *  - `STRICT_RECEIPT_VALIDATION=true` → rechaza (no se permite activar Premium
 *    sin verificación real).
 *  - en otro caso (dev/pre-producción) → infiere el plan por productId con un
 *    `storeVerified=false` que impide acumular plazas permanentes falsas.
 */
export async function validateReceipt(
  receipt: RawReceipt,
  platform: "ios" | "android",
  verifiers?: ReceiptVerifiers,
): Promise<ValidatedEntitlement> {
  const active = verifiers ?? _testVerifiers ?? buildVerifiersFromEnv();
  const verify =
    platform === "android" ? active.verifyGooglePlay : active.verifyAppStore;

  if (verify) {
    const v = await verify(receipt);
    return {
      status: v.status,
      plan: v.plan,
      endsAt: v.endsAt,
      autoRenewEnabled: v.autoRenewEnabled,
      storeVerified: true,
      chargeId: v.chargeId,
    };
  }

  const strict = process.env.STRICT_RECEIPT_VALIDATION === "true";
  if (strict) {
    // En estricto, sin verificador configurado NO se activa Premium.
    logger.error("STRICT_RECEIPT_VALIDATION enabled but verifier missing", {
      platform,
      productId: receipt.productId,
    });
    throw new HttpsError(
      "failed-precondition",
      "Receipt validation backend not configured",
    );
  }

  // Modo dev / pre-producción: inferir plan por productId.
  // Sigue siendo seguro porque (1) el cliente envía el productId que la
  // store le devolvió tras compra real, (2) App Check (`appCheck:true`
  // en la callable) bloquea peticiones desde clientes sin attestation,
  // (3) el chargeId se deriva SERVER-SIDE del purchaseToken y se usa como
  // clave de idempotencia evitando double-credit, y (4) `storeVerified=false`
  // impide acumular créditos de plaza permanentes.
  logger.warn("validateReceipt running in INSECURE inference mode", {
    platform,
    productId: receipt.productId,
  });

  const isAnnual = receipt.productId.toLowerCase().includes("annual");
  const now = Date.now();
  const ms = isAnnual ? 365 * 24 * 60 * 60 * 1000 : 31 * 24 * 60 * 60 * 1000;
  return {
    status: "active",
    plan: isAnnual ? "annual" : "monthly",
    endsAt: new Date(now + ms),
    autoRenewEnabled: true,
    storeVerified: false,
    // chargeId server-side: el purchaseToken (no el purchaseID del cliente).
    chargeId: receipt.purchaseToken,
  };
}
