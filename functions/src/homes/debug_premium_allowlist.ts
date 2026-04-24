// @DEBUG_PREMIUM_REMOVE_BEFORE_PRODUCTION_RELEASE
// Helpers puros usados por debugSetPremiumStatus para decidir si un caller
// puede invocar la función fuera del emulador. Se aislan en un módulo propio
// para poder testearlos sin inicializar firebase-admin.

export function parseDebugPremiumAllowedUids(
  envValue: string | undefined
): ReadonlySet<string> {
  if (!envValue) return new Set();
  return new Set(
    envValue
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0)
  );
}

export function isDebugPremiumAllowed(
  emulatorEnv: string | undefined,
  uid: string | undefined,
  allowedUids: ReadonlySet<string>
): boolean {
  if (emulatorEnv === "true") return true;
  if (!uid) return false;
  return allowedUids.has(uid);
}
