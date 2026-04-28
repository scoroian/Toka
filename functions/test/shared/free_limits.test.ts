import { isPremium, normalizePremiumStatus } from "../../src/shared/free_limits";

describe("free_limits premium helpers", () => {
  describe("isPremium", () => {
    it.each([
      "active",
      "cancelledPendingEnd",
      "cancelled_pending_end",
      "rescue",
    ])("treats %s as premium", (status) => {
      expect(isPremium(status)).toBe(true);
    });

    it.each([
      "free",
      "expiredFree",
      "expired_free",
      "restorable",
      "purged",
      null,
      undefined,
    ])("treats %s as non-premium", (status) => {
      expect(isPremium(status)).toBe(false);
    });
  });

  describe("normalizePremiumStatus", () => {
    it("normalizes legacy cancelled_pending_end", () => {
      expect(normalizePremiumStatus("cancelled_pending_end")).toBe("cancelledPendingEnd");
    });

    it("normalizes legacy expired_free", () => {
      expect(normalizePremiumStatus("expired_free")).toBe("expiredFree");
    });

    it("defaults missing values to free", () => {
      expect(normalizePremiumStatus(null)).toBe("free");
      expect(normalizePremiumStatus(undefined)).toBe("free");
    });

    it("keeps canonical values unchanged", () => {
      expect(normalizePremiumStatus("active")).toBe("active");
      expect(normalizePremiumStatus("cancelledPendingEnd")).toBe("cancelledPendingEnd");
      expect(normalizePremiumStatus("rescue")).toBe("rescue");
    });
  });
});
