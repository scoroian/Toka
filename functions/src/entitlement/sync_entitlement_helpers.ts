// functions/src/entitlement/sync_entitlement_helpers.ts
import { HttpsError } from "firebase-functions/v2/https";

export function parseReceiptData(receiptData: string): {
  status: string;
  plan: string;
  endsAt: Date | null;
  autoRenewEnabled: boolean;
} {
  try {
    const parsed = JSON.parse(receiptData) as {
      status?: string;
      plan?: string;
      endsAt?: string;
      autoRenewEnabled?: boolean;
    };
    return {
      status: parsed.status ?? "active",
      plan: parsed.plan ?? "monthly",
      endsAt: (() => {
        if (!parsed.endsAt) return null;
        const d = new Date(parsed.endsAt);
        if (isNaN(d.getTime())) throw new HttpsError("invalid-argument", "Invalid receipt data format");
        return d;
      })(),
      autoRenewEnabled: parsed.autoRenewEnabled ?? true,
    };
  } catch {
    throw new HttpsError("invalid-argument", "Invalid receipt data format");
  }
}
