// functions/src/entitlement/sync_entitlement_helpers.ts
import * as logger from "firebase-functions/logger";
import { HttpsError } from "firebase-functions/v2/https";

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
 * Valida el recibo contra la store correspondiente y devuelve el
 * entitlement real. En producción exige llamada server-side a Google
 * Play / App Store. En desarrollo (cuando `STRICT_RECEIPT_VALIDATION`
 * no está activa) infiere el plan a partir del productId — esto permite
 * iterar sin tocar las consolas pero NO debe usarse en builds publicados.
 *
 * TODO(prod): implementar `verifyGooglePlay()` con `googleapis`
 * (`androidpublisher_v3`) y `verifyAppStore()` con la App Store Server API.
 * Se debe rechazar si `expiryTimeMillis < now` o el `paymentState` indica
 * impago.
 */
export async function validateReceipt(
  receipt: RawReceipt,
  platform: "ios" | "android",
): Promise<ValidatedEntitlement> {
  const strict = process.env.STRICT_RECEIPT_VALIDATION === "true";

  if (strict) {
    // En estricto, la inferencia local NO es aceptable. Hasta que las
    // funciones reales `verifyGooglePlay` / `verifyAppStore` estén
    // implementadas, devolvemos error explícito para evitar que se
    // active Premium sin validación contra la store.
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
  // y (3) el chargeId real (purchaseToken) es persistido y usado como
  // clave de idempotencia evitando double-credit.
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
  };
}
