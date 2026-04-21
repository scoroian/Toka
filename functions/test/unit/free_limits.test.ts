import {
  FREE_LIMITS,
  FREE_LIMIT_CODES,
  isPremium,
} from "../../src/shared/free_limits";

describe("FREE_LIMITS", () => {
  it("matches spec §6.1 numbers", () => {
    expect(FREE_LIMITS.maxActiveMembers).toBe(3);
    expect(FREE_LIMITS.maxActiveTasks).toBe(4);
    expect(FREE_LIMITS.maxAdminsTotal).toBe(1);
    expect(FREE_LIMITS.maxAutomaticRecurringTasks).toBe(3);
  });
});

describe("isPremium", () => {
  it.each(["active", "cancelledPendingEnd", "rescue"])(
    "returns true for %s",
    (status) => {
      expect(isPremium(status)).toBe(true);
    },
  );

  it.each(["free", "expiredFree", "restorable", "purged", "unknown", ""])(
    "returns false for %s",
    (status) => {
      expect(isPremium(status)).toBe(false);
    },
  );

  it("returns false for null and undefined", () => {
    expect(isPremium(null)).toBe(false);
    expect(isPremium(undefined)).toBe(false);
  });
});

describe("FREE_LIMIT_CODES", () => {
  it("exposes expected error codes", () => {
    expect(FREE_LIMIT_CODES.members).toBe("free_limit_members");
    expect(FREE_LIMIT_CODES.tasks).toBe("free_limit_tasks");
    expect(FREE_LIMIT_CODES.recurring).toBe("free_limit_recurring");
    expect(FREE_LIMIT_CODES.admins).toBe("free_limit_admins");
    expect(FREE_LIMIT_CODES.reviews).toBe("free_no_reviews");
  });
});
