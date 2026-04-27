// functions/src/entitlement/sync_entitlement_helpers.ts
import { HttpsError } from "firebase-functions/v2/https";

const ALLOWED_STATUSES = new Set([
  "active",
  "cancelledPendingEnd",
  "cancelled_pending_end",
  "expiredFree",
  "expired_free",
  "restorable",
  "rescue",
  "free",
]);

const ALLOWED_PLANS = new Set(["monthly", "annual"]);

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

    const status = parsed.status ?? "active";
    const plan = parsed.plan ?? "monthly";

    if (!ALLOWED_STATUSES.has(status)) {
      throw new HttpsError("invalid-argument", "Invalid entitlement status");
    }
    if (!ALLOWED_PLANS.has(plan)) {
      throw new HttpsError("invalid-argument", "Invalid entitlement plan");
    }

    return {
      status,
      plan,
      endsAt: (() => {
        if (!parsed.endsAt) return null;
        const d = new Date(parsed.endsAt);
        if (isNaN(d.getTime())) throw new HttpsError("invalid-argument", "Invalid receipt data format");
        return d;
      })(),
      autoRenewEnabled: parsed.autoRenewEnabled ?? true,
    };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("invalid-argument", "Invalid receipt data format");
  }
}
