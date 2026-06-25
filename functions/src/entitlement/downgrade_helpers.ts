// functions/src/entitlement/downgrade_helpers.ts
import type { Timestamp } from "firebase-admin/firestore";

/**
 * Estados de `premiumStatus` elegibles para downgrade automático cuando
 * `premiumEndsAt <= now`. Incluye:
 *  - `rescue` y `cancelled_pending_end`/`cancelledPendingEnd`: flujo normal de
 *    cancelación → rescate → downgrade.
 *  - `active`: un hogar cuyo periodo venció SIN que llegara una renovación (p. ej.
 *    fallo de cobro involuntario o RTDN perdida). Sin esta rama quedaría en
 *    Premium efectivo perpetuo (Hallazgo #06). El handler RTDN mantiene
 *    `premiumEndsAt` al día en renovaciones legítimas, así que un hogar
 *    realmente activo conserva un endsAt futuro y NO se captura aquí.
 */
export const DOWNGRADE_ELIGIBLE_STATUSES = [
  "active",
  "rescue",
  "cancelled_pending_end",
  "cancelledPendingEnd",
] as const;

/** Predicado de elegibilidad usado por el cron (premiumEndsAt <= now). */
export function isDowngradeEligible(
  premiumStatus: string,
  premiumEndsAtMs: number | null | undefined,
  nowMs: number,
): boolean {
  if (premiumEndsAtMs == null) return false; // sin fecha de fin → no degradar
  return (
    (DOWNGRADE_ELIGIBLE_STATUSES as readonly string[]).includes(premiumStatus) &&
    premiumEndsAtMs <= nowMs
  );
}

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

/**
 * Selecciona qué miembros y tareas se MANTIENEN activos en un downgrade,
 * congelando el resto. El owner siempre se mantiene; entre los demás gana el
 * más participativo (completions60d, desempate por lastCompletedAt y antigüedad).
 *
 * `maxMembers` / `maxTasks` parametrizan el tope objetivo: por defecto Free
 * (3 miembros = owner + 2; 4 tareas), pero el downgrade entre tiers pasa el
 * tope del tier destino para reutilizar exactamente este criterio de selección.
 */
export function autoSelectForDowngrade(
  members: Member[],
  tasks: Task[],
  ownerId: string,
  maxMembers = 3,
  maxTasks = 4,
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

  // Se conserva el owner + los (maxMembers-1) no-owner más activos.
  const nonOwnerKeep = Math.max(0, maxMembers - 1);
  const selectedMemberIds = [
    ownerId,
    ...sortedMembers.slice(0, nonOwnerKeep).map((m) => m.uid),
  ];

  const sortedTasks = tasks
    .filter((t) => t.status === "active")
    .sort((a, b) => {
      if (b.completedCount90d !== a.completedCount90d) return b.completedCount90d - a.completedCount90d;
      return a.nextDueAt.seconds - b.nextDueAt.seconds;
    });

  const selectedTaskIds = sortedTasks.slice(0, maxTasks).map((t) => t.id);

  return { selectedMemberIds, selectedTaskIds, mode: "auto" };
}
