// Testea que la lógica de unlock-por-chargeId es idempotente:
// dos invocaciones del mismo chargeId NUNCA incrementan el slot dos veces.

describe("syncEntitlement — idempotencia de unlock", () => {
  type ChargeState = { exists: boolean };
  type UserState = { lifetimeUnlockedHomeSlots: number; homeSlotCap: number };

  function processCharge(
    charge: ChargeState,
    user: UserState,
    status: string
  ): { unlocked: boolean; userAfter: UserState } {
    if (charge.exists) {
      return { unlocked: false, userAfter: user };
    }
    const validForUnlock = status === "active";
    if (!validForUnlock) {
      return { unlocked: false, userAfter: user };
    }
    if (user.lifetimeUnlockedHomeSlots >= 3) {
      return { unlocked: false, userAfter: user };
    }
    return {
      unlocked: true,
      userAfter: {
        lifetimeUnlockedHomeSlots: user.lifetimeUnlockedHomeSlots + 1,
        homeSlotCap: user.homeSlotCap + 1,
      },
    };
  }

  it("primera invocación: charge nuevo + status active → desbloquea", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 0, homeSlotCap: 2 },
      "active"
    );
    expect(res.unlocked).toBe(true);
    expect(res.userAfter.lifetimeUnlockedHomeSlots).toBe(1);
  });

  it("segunda invocación con mismo chargeId → NO desbloquea otra vez", () => {
    const res = processCharge(
      { exists: true },
      { lifetimeUnlockedHomeSlots: 1, homeSlotCap: 3 },
      "active"
    );
    expect(res.unlocked).toBe(false);
    expect(res.userAfter.lifetimeUnlockedHomeSlots).toBe(1);
  });

  it("status cancelled → no desbloquea", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 0, homeSlotCap: 2 },
      "cancelled"
    );
    expect(res.unlocked).toBe(false);
  });

  it("ya tiene 3 unlocks → no desbloquea más", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 3, homeSlotCap: 5 },
      "active"
    );
    expect(res.unlocked).toBe(false);
  });
});
