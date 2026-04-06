// functions/src/entitlement/downgrade_helpers.ts
import type { Timestamp } from "firebase-admin/firestore";

type Member = {
  uid: string;
  status: string;
  completions60d: number;
  lastCompletedAt: Timestamp | null;
  joinedAt: Timestamp;
};

type Task = {
  id: string;
  status: string;
  completedCount90d: number;
  nextDueAt: Timestamp;
};

export type DowngradeSelection = {
  selectedMemberIds: string[];
  selectedTaskIds: string[];
  mode: "auto";
};

export function autoSelectForDowngrade(
  members: Member[],
  tasks: Task[],
  ownerId: string,
): DowngradeSelection {
  const sortedMembers = members
    .filter((m) => m.uid !== ownerId && m.status === "active")
    .sort((a, b) => {
      if (b.completions60d !== a.completions60d) return b.completions60d - a.completions60d;
      if (b.lastCompletedAt && a.lastCompletedAt) {
        return b.lastCompletedAt.seconds - a.lastCompletedAt.seconds;
      }
      if (b.lastCompletedAt && !a.lastCompletedAt) return 1;
      if (!b.lastCompletedAt && a.lastCompletedAt) return -1;
      return a.joinedAt.seconds - b.joinedAt.seconds;
    });

  const selectedMemberIds = [ownerId, ...sortedMembers.slice(0, 2).map((m) => m.uid)];

  const sortedTasks = tasks
    .filter((t) => t.status === "active")
    .sort((a, b) => {
      if (b.completedCount90d !== a.completedCount90d) return b.completedCount90d - a.completedCount90d;
      return a.nextDueAt.seconds - b.nextDueAt.seconds;
    });

  const selectedTaskIds = sortedTasks.slice(0, 4).map((t) => t.id);

  return { selectedMemberIds, selectedTaskIds, mode: "auto" };
}
