// functions/src/jobs/jobs.test.ts

describe("purgeExpiredFrozen — lógica de selección", () => {
  function shouldPurge(premiumStatus: string, restoreUntilMs: number, nowMs: number): boolean {
    return premiumStatus === "restorable" && restoreUntilMs <= nowMs;
  }

  it("restorable con ventana expirada → purgar", () => {
    const past = Date.now() - 1000;
    expect(shouldPurge("restorable", past, Date.now())).toBe(true);
  });
  it("restorable con ventana activa → no purgar", () => {
    const future = Date.now() + 86400000;
    expect(shouldPurge("restorable", future, Date.now())).toBe(false);
  });
  it("free → no purgar", () => {
    expect(shouldPurge("free", Date.now() - 1000, Date.now())).toBe(false);
  });
});

describe("restorePremiumState — validaciones", () => {
  function canRestore(premiumStatus: string): { ok: boolean; reason?: string } {
    if (premiumStatus === "purged") return { ok: false, reason: "restore_window_expired" };
    if (premiumStatus !== "restorable") return { ok: false, reason: `not_restorable: ${premiumStatus}` };
    return { ok: true };
  }

  it("restorable → puede restaurar", () => {
    expect(canRestore("restorable").ok).toBe(true);
  });
  it("purged → no puede restaurar con razón correcta", () => {
    const r = canRestore("purged");
    expect(r.ok).toBe(false);
    expect(r.reason).toBe("restore_window_expired");
  });
  it("active → no puede restaurar", () => {
    expect(canRestore("active").ok).toBe(false);
  });
  it("free → no puede restaurar", () => {
    expect(canRestore("free").ok).toBe(false);
  });
});

describe("openRescueWindow — ventana de rescate", () => {
  function needsRescue(
    premiumStatus: string,
    premiumEndsAtMs: number,
    nowMs: number,
    alreadyInRescue: boolean
  ): boolean {
    if (alreadyInRescue) return false;
    if (premiumStatus !== "cancelled_pending_end") return false;
    const threeDaysMs = 3 * 24 * 60 * 60 * 1000;
    return premiumEndsAtMs <= nowMs + threeDaysMs;
  }

  it("cancelled con menos de 3 días → necesita rescue", () => {
    const in2days = Date.now() + 2 * 24 * 60 * 60 * 1000;
    expect(needsRescue("cancelled_pending_end", in2days, Date.now(), false)).toBe(true);
  });
  it("cancelled con más de 3 días → no necesita rescue", () => {
    const in5days = Date.now() + 5 * 24 * 60 * 60 * 1000;
    expect(needsRescue("cancelled_pending_end", in5days, Date.now(), false)).toBe(false);
  });
  it("ya en rescue → no procesar", () => {
    const in1day = Date.now() + 1 * 24 * 60 * 60 * 1000;
    expect(needsRescue("cancelled_pending_end", in1day, Date.now(), true)).toBe(false);
  });
  it("active → no necesita rescue aunque esté cerca", () => {
    const in1day = Date.now() + 1 * 24 * 60 * 60 * 1000;
    expect(needsRescue("active", in1day, Date.now(), false)).toBe(false);
  });
});
