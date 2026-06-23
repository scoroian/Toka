// functions/src/shared/log.ts
//
// Hallazgo #17 — Logging estructurado consistente.
// El logging del backend era ad-hoc (strings interpolados) y NO llevaba
// homeId/uid/correlationId de forma consistente, así que era imposible
// reconstruir el historial de un usuario en Cloud Logging. Este helper fuerza
// una forma común: cada entrada lleva `event` + los campos de correlación, de
// modo que se puede filtrar por `jsonPayload.homeId` / `jsonPayload.uid` /
// `jsonPayload.correlationId`.
//
// IMPORTANTE: nunca se debe pasar el token FCM ni el teléfono a estos campos.

import * as logger from "firebase-functions/logger";
import { randomUUID } from "crypto";

/** Identificador de correlación para enlazar todos los logs de una misma
 * operación (una ejecución de un job, una invocación de callable, etc.). */
export function newCorrelationId(): string {
  return randomUUID();
}

export interface LogFields {
  homeId?: string | null;
  uid?: string | null;
  correlationId?: string | null;
  [key: string]: unknown;
}

/**
 * Emite una entrada de log estructurada con forma consistente
 * `{ event, ...fields }`. El primer argumento textual (`event`) es el mensaje
 * legible en Cloud Logging; el objeto es el `jsonPayload` indexable.
 */
export function logEvent(
  level: "info" | "warn" | "error",
  event: string,
  fields: LogFields = {}
): void {
  const payload = { event, ...fields };
  if (level === "warn") {
    logger.warn(event, payload);
  } else if (level === "error") {
    logger.error(event, payload);
  } else {
    logger.info(event, payload);
  }
}
