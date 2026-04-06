import { autoSelectForDowngrade } from "./downgrade_helpers";
import type { Timestamp } from "firebase-admin/firestore";

type MemberInput = {
  uid: string;
  status: string;
  completions60d: number;
  lastCompletedAt: Timestamp | null;
  joinedAt: Timestamp;
};

type TaskInput = {
  id: string;
  status: string;
  completedCount90d: number;
  nextDueAt: Timestamp;
};

function makeTimestamp(secondsOffset = 0): Timestamp {
  return { seconds: Math.floor(Date.now() / 1000) + secondsOffset, nanoseconds: 0 } as unknown as Timestamp;
}

const ownerId = "owner-uid";

describe("autoSelectForDowngrade – miembros", () => {
  it("selecciona owner + los 2 más participativos de 5 miembros", () => {
    const members: MemberInput[] = [
      { uid: ownerId, status: "active", completions60d: 10, lastCompletedAt: null, joinedAt: makeTimestamp(-100) },
      { uid: "m1", status: "active", completions60d: 8, lastCompletedAt: makeTimestamp(-10), joinedAt: makeTimestamp(-90) },
      { uid: "m2", status: "active", completions60d: 5, lastCompletedAt: makeTimestamp(-20), joinedAt: makeTimestamp(-80) },
      { uid: "m3", status: "active", completions60d: 3, lastCompletedAt: makeTimestamp(-30), joinedAt: makeTimestamp(-70) },
      { uid: "m4", status: "active", completions60d: 1, lastCompletedAt: makeTimestamp(-40), joinedAt: makeTimestamp(-60) },
    ];
    const result = autoSelectForDowngrade(members, [], ownerId);
    expect(result.selectedMemberIds).toContain(ownerId);
    expect(result.selectedMemberIds).toContain("m1");
    expect(result.selectedMemberIds).toContain("m2");
    expect(result.selectedMemberIds).toHaveLength(3);
  });

  it("desempata por lastCompletedAt: el más reciente gana", () => {
    const now = Math.floor(Date.now() / 1000);
    const members: MemberInput[] = [
      { uid: ownerId, status: "active", completions60d: 10, lastCompletedAt: null, joinedAt: makeTimestamp(-100) },
      { uid: "m1", status: "active", completions60d: 5, lastCompletedAt: { seconds: now - 10, nanoseconds: 0 } as unknown as Timestamp, joinedAt: makeTimestamp(-80) },
      { uid: "m2", status: "active", completions60d: 5, lastCompletedAt: { seconds: now - 5, nanoseconds: 0 } as unknown as Timestamp, joinedAt: makeTimestamp(-70) },
      { uid: "m3", status: "active", completions60d: 5, lastCompletedAt: { seconds: now - 20, nanoseconds: 0 } as unknown as Timestamp, joinedAt: makeTimestamp(-60) },
    ];
    const result = autoSelectForDowngrade(members, [], ownerId);
    expect(result.selectedMemberIds).toContain("m2"); // más reciente (now-5)
    expect(result.selectedMemberIds).toContain("m1"); // segundo más reciente (now-10)
    expect(result.selectedMemberIds).not.toContain("m3");
  });

  it("con empate en lastCompletedAt null, gana el más antiguo (menor joinedAt.seconds)", () => {
    const now = Math.floor(Date.now() / 1000);
    const members: MemberInput[] = [
      { uid: ownerId, status: "active", completions60d: 10, lastCompletedAt: null, joinedAt: makeTimestamp(-100) },
      { uid: "m1", status: "active", completions60d: 5, lastCompletedAt: null, joinedAt: { seconds: now - 50, nanoseconds: 0 } as unknown as Timestamp },
      { uid: "m2", status: "active", completions60d: 5, lastCompletedAt: null, joinedAt: { seconds: now - 30, nanoseconds: 0 } as unknown as Timestamp },
      { uid: "m3", status: "active", completions60d: 5, lastCompletedAt: null, joinedAt: { seconds: now - 10, nanoseconds: 0 } as unknown as Timestamp },
    ];
    const result = autoSelectForDowngrade(members, [], ownerId);
    expect(result.selectedMemberIds).toContain("m1"); // más antiguo (now-50)
    expect(result.selectedMemberIds).toContain("m2"); // segundo (now-30)
    expect(result.selectedMemberIds).not.toContain("m3");
  });
});

describe("autoSelectForDowngrade – tareas", () => {
  it("selecciona las 4 tareas con más completedCount90d de 6", () => {
    const tasks: TaskInput[] = [
      { id: "t1", status: "active", completedCount90d: 20, nextDueAt: makeTimestamp(1) },
      { id: "t2", status: "active", completedCount90d: 15, nextDueAt: makeTimestamp(2) },
      { id: "t3", status: "active", completedCount90d: 10, nextDueAt: makeTimestamp(3) },
      { id: "t4", status: "active", completedCount90d: 8, nextDueAt: makeTimestamp(4) },
      { id: "t5", status: "active", completedCount90d: 5, nextDueAt: makeTimestamp(5) },
      { id: "t6", status: "active", completedCount90d: 2, nextDueAt: makeTimestamp(6) },
    ];
    const result = autoSelectForDowngrade([], tasks, ownerId);
    expect(result.selectedTaskIds).toEqual(["t1", "t2", "t3", "t4"]);
  });

  it("retorna mode: 'auto'", () => {
    const result = autoSelectForDowngrade([], [], ownerId);
    expect(result.mode).toBe("auto");
  });
});
