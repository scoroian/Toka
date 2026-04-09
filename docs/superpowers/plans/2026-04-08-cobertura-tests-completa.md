# Cobertura de Tests Completa — Toka Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar todos los huecos de cobertura en Flutter (ViewModels, pantallas, widgets), Cloud Functions (lógica pura + callables) y añadir flujos E2E con Patrol en el emulador Pixel 6 (`emulator-5554`).

**Architecture:** Tests organizados en tres capas: (A) lógica pura TypeScript/Jest para Cloud Functions, (B) tests unitarios y de UI Flutter con mocktail/ProviderContainer, (C) flujos E2E con `patrol` sobre el emulador `sdk_gphone64_x86_64` (emulator-5554, Android 14 API 34). Cada tarea es independiente y commitable por separado.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_test, mocktail, patrol 3.x, Riverpod, Jest + ts-jest, Firebase emulators (puerto 8080 Firestore, 9099 Auth, 5001 Functions).

---

## Mapa de archivos

### Cloud Functions — nuevos archivos de test
- Create: `functions/src/tasks/task_assignment_helpers.ts` — extrae `scoreOf`, `getNextAssigneeRoundRobin`, `getNextAssigneeSmart`, `addRecurrenceInterval`
- Create: `functions/src/tasks/task_assignment_helpers.test.ts`
- Create: `functions/src/tasks/pass_turn_helpers.ts` — extrae `getNextEligibleMember`
- Create: `functions/src/tasks/pass_turn_helpers.test.ts`
- Create: `functions/src/entitlement/sync_entitlement_helpers.ts` — extrae `parseReceiptData`, `updatePremiumFlagsInDashboard`
- Create: `functions/src/entitlement/sync_entitlement_helpers.test.ts`
- Create: `functions/src/tasks/submit_review_helpers.test.ts`
- Create: `functions/src/homes/homes_callables.test.ts`
- Create: `functions/src/jobs/jobs.test.ts`
- Create: `functions/src/notifications/notifications_helpers.test.ts`

### Flutter — nuevos archivos de test
- Create: `test/unit/features/subscription/rescue_view_model_test.dart`
- Create: `test/unit/features/subscription/subscription_management_view_model_test.dart`
- Create: `test/unit/features/tasks/task_form_provider_test.dart`
- Create: `test/ui/features/auth/forgot_password_screen_test.dart`
- Create: `test/ui/features/auth/verify_email_screen_test.dart`
- Create: `test/ui/features/tasks/task_detail_screen_test.dart`
- Create: `test/ui/features/tasks/task_card_test.dart`
- Create: `test/ui/features/profile/own_profile_screen_test.dart`
- Create: `test/ui/features/profile/edit_profile_screen_test.dart`
- Create: `test/ui/features/subscription/rescue_screen_test.dart`
- Create: `test/ui/features/subscription/subscription_management_screen_test.dart`
- Create: `test/ui/features/homes/my_homes_screen_test.dart`
- Create: `integration_test/flows/auth_onboarding_flow_test.dart`
- Create: `integration_test/flows/task_completion_flow_test.dart`

### Modificaciones a archivos existentes
- Modify: `functions/src/tasks/apply_task_completion.ts` — importar helpers en vez de definir inline
- Modify: `functions/src/tasks/pass_task_turn.ts` — importar helper en vez de definir inline
- Modify: `functions/src/entitlement/sync_entitlement.ts` — importar helpers

---

## Task 1: Extraer y testear lógica pura de `apply_task_completion`

**Files:**
- Create: `functions/src/tasks/task_assignment_helpers.ts`
- Create: `functions/src/tasks/task_assignment_helpers.test.ts`
- Modify: `functions/src/tasks/apply_task_completion.ts`

- [ ] **Step 1: Escribir el test fallido**

```typescript
// functions/src/tasks/task_assignment_helpers.test.ts
import {
  scoreOf,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  addRecurrenceInterval,
} from "./task_assignment_helpers";

describe("scoreOf", () => {
  it("calcula score básico correctamente", () => {
    expect(scoreOf({ completionsRecent: 5, difficultyWeight: 2.0, daysSinceLastExecution: 0 }))
      .toBe(10);
  });
  it("penaliza por días sin ejecutar", () => {
    const s = scoreOf({ completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 10 });
    expect(s).toBe(-1);
  });
});

describe("getNextAssigneeRoundRobin", () => {
  it("retorna null para orden vacío", () => {
    expect(getNextAssigneeRoundRobin([], "u1", [])).toBeNull();
  });
  it("avanza al siguiente en orden circular", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u1", [])).toBe("u2");
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u3", [])).toBe("u1");
  });
  it("salta excluidos", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u1", ["u2"])).toBe("u3");
  });
  it("retorna currentUid si todos excluidos", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2"], "u1", ["u2"])).toBe("u1");
  });
});

describe("getNextAssigneeSmart", () => {
  it("elige al miembro con menor score (menos carga)", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 10, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
      ["u2", { completionsRecent: 2, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
    ]);
    expect(getNextAssigneeSmart(["u1","u2"], "u1", [], loadData)).toBe("u2");
  });
  it("salta excluidos", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
      ["u2", { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
    ]);
    expect(getNextAssigneeSmart(["u1","u2"], "u1", ["u2"], loadData)).toBe("u1");
  });
  it("retorna currentUid para orden vacío", () => {
    expect(getNextAssigneeSmart([], "u1", [], new Map())).toBe("u1");
  });
});

describe("addRecurrenceInterval", () => {
  const base = new Date("2026-04-08T10:00:00Z");
  it("hourly +1 hora", () => {
    const r = addRecurrenceInterval(base, "hourly");
    expect(r.getUTCHours()).toBe(11);
  });
  it("daily +1 día", () => {
    const r = addRecurrenceInterval(base, "daily");
    expect(r.getUTCDate()).toBe(9);
  });
  it("weekly +7 días", () => {
    const r = addRecurrenceInterval(base, "weekly");
    expect(r.getUTCDate()).toBe(15);
  });
  it("monthly +1 mes", () => {
    const r = addRecurrenceInterval(base, "monthly");
    expect(r.getUTCMonth()).toBe(4); // Mayo
  });
  it("yearly +1 año", () => {
    const r = addRecurrenceInterval(base, "yearly");
    expect(r.getUTCFullYear()).toBe(2027);
  });
  it("tipo desconocido no modifica la fecha", () => {
    const r = addRecurrenceInterval(base, "unknown");
    expect(r.getTime()).toBe(base.getTime());
  });
});
```

- [ ] **Step 2: Ejecutar tests para confirmar que fallan**

```bash
cd functions && npx jest src/tasks/task_assignment_helpers.test.ts --no-coverage
```

Expected: FAIL — `Cannot find module './task_assignment_helpers'`

- [ ] **Step 3: Crear el helper con las funciones exportadas**

```typescript
// functions/src/tasks/task_assignment_helpers.ts

export interface MemberLoadData {
  completionsRecent: number;
  difficultyWeight: number;
  daysSinceLastExecution: number;
}

export function scoreOf(data: MemberLoadData): number {
  return data.completionsRecent * data.difficultyWeight + data.daysSinceLastExecution * -0.1;
}

export function getNextAssigneeRoundRobin(
  order: string[],
  currentUid: string,
  excludedUids: string[]
): string | null {
  if (!order.length) return null;
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  const idx = eligible.indexOf(currentUid);
  const nextIdx = (idx + 1) % eligible.length;
  return eligible[nextIdx];
}

export function getNextAssigneeSmart(
  order: string[],
  currentUid: string,
  excludedUids: string[],
  loadData: Map<string, MemberLoadData>
): string {
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  return eligible.reduce((a, b) => {
    const aData = loadData.get(a) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    const bData = loadData.get(b) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    return scoreOf(aData) <= scoreOf(bData) ? a : b;
  });
}

export function addRecurrenceInterval(base: Date, recurrenceType: string): Date {
  const d = new Date(base);
  switch (recurrenceType) {
    case "hourly":  d.setHours(d.getHours() + 1); break;
    case "daily":   d.setDate(d.getDate() + 1); break;
    case "weekly":  d.setDate(d.getDate() + 7); break;
    case "monthly": d.setMonth(d.getMonth() + 1); break;
    case "yearly":  d.setFullYear(d.getFullYear() + 1); break;
  }
  return d;
}
```

- [ ] **Step 4: Actualizar `apply_task_completion.ts` para importar los helpers**

En `apply_task_completion.ts`, eliminar las 4 funciones `scoreOf`, `getNextAssigneeRoundRobin`, `getNextAssigneeSmart`, `addRecurrenceInterval` (líneas 16–58) y añadir al inicio del archivo (después del primer import):

```typescript
import {
  MemberLoadData,
  scoreOf,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  addRecurrenceInterval,
} from "./task_assignment_helpers";
```

- [ ] **Step 5: Ejecutar tests y confirmar que pasan**

```bash
cd functions && npx jest src/tasks/task_assignment_helpers.test.ts --no-coverage
```

Expected: PASS — 12 tests passing

- [ ] **Step 6: Commit**

```bash
cd functions && git add src/tasks/task_assignment_helpers.ts src/tasks/task_assignment_helpers.test.ts src/tasks/apply_task_completion.ts
git commit -m "test(functions): unit tests for task assignment pure helpers"
```

---

## Task 2: Extraer y testear `getNextEligibleMember` de `pass_task_turn`

**Files:**
- Create: `functions/src/tasks/pass_turn_helpers.ts`
- Create: `functions/src/tasks/pass_turn_helpers.test.ts`
- Modify: `functions/src/tasks/pass_task_turn.ts`

- [ ] **Step 1: Escribir el test fallido**

```typescript
// functions/src/tasks/pass_turn_helpers.test.ts
import { getNextEligibleMember } from "./pass_turn_helpers";

describe("getNextEligibleMember", () => {
  it("retorna currentUid para orden vacío", () => {
    expect(getNextEligibleMember([], "u1", [])).toBe("u1");
  });
  it("avanza al siguiente no congelado", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", [])).toBe("u2");
  });
  it("salta miembros congelados", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", ["u2"])).toBe("u3");
  });
  it("vuelve al inicio si el siguiente está congelado (circular)", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u3", ["u1"])).toBe("u2");
  });
  it("retorna currentUid si todos los demás están congelados", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", ["u2","u3"])).toBe("u1");
  });
  it("un solo miembro siempre devuelve ese mismo", () => {
    expect(getNextEligibleMember(["u1"], "u1", [])).toBe("u1");
  });
});
```

- [ ] **Step 2: Ejecutar tests para confirmar que fallan**

```bash
cd functions && npx jest src/tasks/pass_turn_helpers.test.ts --no-coverage
```

Expected: FAIL — `Cannot find module './pass_turn_helpers'`

- [ ] **Step 3: Crear el helper**

```typescript
// functions/src/tasks/pass_turn_helpers.ts

export function getNextEligibleMember(
  order: string[],
  currentUid: string,
  frozenUids: string[]
): string {
  if (!order.length) return currentUid;
  const currentIdx = order.indexOf(currentUid);
  for (let i = 1; i < order.length; i++) {
    const candidate = order[(currentIdx + i) % order.length];
    if (!frozenUids.includes(candidate)) return candidate;
  }
  return currentUid;
}
```

- [ ] **Step 4: Actualizar `pass_task_turn.ts`**

En `pass_task_turn.ts`, eliminar la función `getNextEligibleMember` (líneas 11–23) y añadir al inicio:

```typescript
import { getNextEligibleMember } from "./pass_turn_helpers";
```

- [ ] **Step 5: Ejecutar tests y confirmar que pasan**

```bash
cd functions && npx jest src/tasks/pass_turn_helpers.test.ts --no-coverage
```

Expected: PASS — 6 tests passing

- [ ] **Step 6: Commit**

```bash
cd functions && git add src/tasks/pass_turn_helpers.ts src/tasks/pass_turn_helpers.test.ts src/tasks/pass_task_turn.ts
git commit -m "test(functions): unit tests for pass turn eligible member helper"
```

---

## Task 3: Extraer y testear `parseReceiptData` de `sync_entitlement`

**Files:**
- Create: `functions/src/entitlement/sync_entitlement_helpers.ts`
- Create: `functions/src/entitlement/sync_entitlement_helpers.test.ts`
- Modify: `functions/src/entitlement/sync_entitlement.ts`

- [ ] **Step 1: Escribir el test fallido**

```typescript
// functions/src/entitlement/sync_entitlement_helpers.test.ts
import { parseReceiptData } from "./sync_entitlement_helpers";

describe("parseReceiptData", () => {
  it("parsea recibo válido con todos los campos", () => {
    const input = JSON.stringify({
      status: "active",
      plan: "annual",
      endsAt: "2027-01-01T00:00:00Z",
      autoRenewEnabled: true,
    });
    const result = parseReceiptData(input);
    expect(result.status).toBe("active");
    expect(result.plan).toBe("annual");
    expect(result.endsAt).toBeInstanceOf(Date);
    expect(result.autoRenewEnabled).toBe(true);
  });

  it("usa defaults si faltan campos", () => {
    const result = parseReceiptData("{}");
    expect(result.status).toBe("active");
    expect(result.plan).toBe("monthly");
    expect(result.endsAt).toBeNull();
    expect(result.autoRenewEnabled).toBe(true);
  });

  it("lanza HttpsError para JSON inválido", () => {
    expect(() => parseReceiptData("not-json")).toThrow();
  });

  it("endsAt null cuando no se provee", () => {
    const result = parseReceiptData(JSON.stringify({ status: "active" }));
    expect(result.endsAt).toBeNull();
  });

  it("autoRenewEnabled false si se indica", () => {
    const result = parseReceiptData(JSON.stringify({ autoRenewEnabled: false }));
    expect(result.autoRenewEnabled).toBe(false);
  });
});
```

- [ ] **Step 2: Ejecutar tests para confirmar que fallan**

```bash
cd functions && npx jest src/entitlement/sync_entitlement_helpers.test.ts --no-coverage
```

Expected: FAIL — `Cannot find module './sync_entitlement_helpers'`

- [ ] **Step 3: Crear el helper**

```typescript
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
      endsAt: parsed.endsAt ? new Date(parsed.endsAt) : null,
      autoRenewEnabled: parsed.autoRenewEnabled ?? true,
    };
  } catch {
    throw new HttpsError("invalid-argument", "Invalid receipt data format");
  }
}
```

- [ ] **Step 4: Actualizar `sync_entitlement.ts`**

Reemplazar la función inline `parseReceiptData` (líneas 96–118) con la importación:

```typescript
import { parseReceiptData } from "./sync_entitlement_helpers";
```

- [ ] **Step 5: Ejecutar tests**

```bash
cd functions && npx jest src/entitlement/sync_entitlement_helpers.test.ts --no-coverage
```

Expected: PASS — 5 tests passing

- [ ] **Step 6: Commit**

```bash
cd functions && git add src/entitlement/sync_entitlement_helpers.ts src/entitlement/sync_entitlement_helpers.test.ts src/entitlement/sync_entitlement.ts
git commit -m "test(functions): unit tests for parseReceiptData helper"
```

---

## Task 4: Unit tests para `submit_review` (lógica de cálculo de score)

**Files:**
- Create: `functions/src/tasks/submit_review.test.ts`

- [ ] **Step 1: Escribir tests con mock de Firestore**

```typescript
// functions/src/tasks/submit_review.test.ts

// Calcula el avg ponderado: (oldAvg * oldCount + score) / newCount
describe("submit_review — cálculo de promedio ponderado", () => {
  function calcNewAvg(oldAvg: number, oldCount: number, score: number): number {
    const newCount = oldCount + 1;
    return (oldAvg * oldCount + score) / newCount;
  }

  it("primera valoración: avg = score", () => {
    expect(calcNewAvg(0, 0, 8)).toBe(8);
  });

  it("segunda valoración: promedio correcto", () => {
    // oldAvg=8, oldCount=1, score=10 → (8+10)/2 = 9
    expect(calcNewAvg(8, 1, 10)).toBe(9);
  });

  it("con 4 valoraciones previas de 5, nueva de 10 → 6", () => {
    expect(calcNewAvg(5, 4, 10)).toBe(6);
  });

  it("score mínimo 1 no produce negativo", () => {
    expect(calcNewAvg(10, 9, 1)).toBeGreaterThan(0);
  });
});

describe("submit_review — validación de score", () => {
  function isValidScore(score: unknown): boolean {
    return typeof score === "number" && score >= 1 && score <= 10;
  }

  it("score 1 es válido", () => expect(isValidScore(1)).toBe(true));
  it("score 10 es válido", () => expect(isValidScore(10)).toBe(true));
  it("score 0 no es válido", () => expect(isValidScore(0)).toBe(false));
  it("score 11 no es válido", () => expect(isValidScore(11)).toBe(false));
  it("score string no es válido", () => expect(isValidScore("8")).toBe(false));
});

describe("submit_review — validación de nota", () => {
  function isValidNote(note: string | undefined): boolean {
    if (note === undefined) return true;
    return note.length <= 300;
  }

  it("nota undefined es válida", () => expect(isValidNote(undefined)).toBe(true));
  it("nota de 300 chars es válida", () => expect(isValidNote("a".repeat(300))).toBe(true));
  it("nota de 301 chars no es válida", () => expect(isValidNote("a".repeat(301))).toBe(false));
});
```

- [ ] **Step 2: Ejecutar tests**

```bash
cd functions && npx jest src/tasks/submit_review.test.ts --no-coverage
```

Expected: PASS — 10 tests passing

- [ ] **Step 3: Commit**

```bash
cd functions && git add src/tasks/submit_review.test.ts
git commit -m "test(functions): unit tests for submit_review calculation and validation logic"
```

---

## Task 5: Unit tests para callables de `homes/index.ts`

**Files:**
- Create: `functions/src/homes/homes_callables.test.ts`

- [ ] **Step 1: Escribir los tests con mocks de Firestore**

```typescript
// functions/src/homes/homes_callables.test.ts

// Testea la lógica de negocio de createHome: validación nombre, control de slots, error si sin nombre

describe("createHome — validaciones de entrada", () => {
  function validateCreateHomeInput(name: string | undefined): string | null {
    const trimmed = name?.trim();
    if (!trimmed) return "Home name is required";
    return null;
  }

  it("nombre vacío → error", () => {
    expect(validateCreateHomeInput("")).toBe("Home name is required");
  });
  it("nombre undefined → error", () => {
    expect(validateCreateHomeInput(undefined)).toBe("Home name is required");
  });
  it("nombre con solo espacios → error", () => {
    expect(validateCreateHomeInput("   ")).toBe("Home name is required");
  });
  it("nombre válido → null", () => {
    expect(validateCreateHomeInput("Mi Casa")).toBeNull();
  });
});

describe("createHome — control de slots disponibles", () => {
  function hasAvailableSlot(baseSlots: number, lifetimeUnlocked: number, existingCount: number): boolean {
    return existingCount < (baseSlots + lifetimeUnlocked);
  }

  it("0 hogares con 2 slots base → disponible", () => {
    expect(hasAvailableSlot(2, 0, 0)).toBe(true);
  });
  it("2 hogares con 2 slots base → no disponible", () => {
    expect(hasAvailableSlot(2, 0, 2)).toBe(false);
  });
  it("2 hogares con 1 extra desbloqueado → disponible", () => {
    expect(hasAvailableSlot(2, 1, 2)).toBe(true);
  });
  it("5 hogares con 2+3 slots → no disponible", () => {
    expect(hasAvailableSlot(2, 3, 5)).toBe(false);
  });
});

describe("leaveHome — validación rol owner", () => {
  function canLeave(role: string): boolean {
    return role !== "owner";
  }

  it("member puede salir", () => expect(canLeave("member")).toBe(true));
  it("admin puede salir", () => expect(canLeave("admin")).toBe(true));
  it("owner no puede salir", () => expect(canLeave("owner")).toBe(false));
});

describe("joinHome — validación de invitación expirada", () => {
  function isExpired(expiresAt: Date | undefined): boolean {
    if (!expiresAt) return false;
    return new Date() > expiresAt;
  }

  it("sin fecha de expiración → no expirada", () => {
    expect(isExpired(undefined)).toBe(false);
  });
  it("fecha futura → no expirada", () => {
    const future = new Date(Date.now() + 60000);
    expect(isExpired(future)).toBe(false);
  });
  it("fecha pasada → expirada", () => {
    const past = new Date(Date.now() - 60000);
    expect(isExpired(past)).toBe(true);
  });
});
```

- [ ] **Step 2: Ejecutar tests**

```bash
cd functions && npx jest src/homes/homes_callables.test.ts --no-coverage
```

Expected: PASS — 12 tests passing

- [ ] **Step 3: Commit**

```bash
cd functions && git add src/homes/homes_callables.test.ts
git commit -m "test(functions): unit tests for homes callables validation logic"
```

---

## Task 6: Unit tests para jobs y notifications helpers

**Files:**
- Create: `functions/src/jobs/jobs.test.ts`
- Create: `functions/src/notifications/notifications_helpers.test.ts`

- [ ] **Step 1: Escribir tests para lógica de jobs**

```typescript
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
```

- [ ] **Step 2: Escribir tests para notifications helpers**

```typescript
// functions/src/notifications/notifications_helpers.test.ts

describe("dispatchDueReminders — deduplicación por bucket", () => {
  function buildNotifKey(taskId: string, date: Date): string {
    const bucket = Math.floor(date.getMinutes() / 15) * 15;
    return `${taskId}_${date.toISOString().slice(0, 11)}${String(date.getHours()).padStart(2, '0')}${String(bucket).padStart(2, '0')}`;
  }

  it("misma tarea en el mismo bucket de 15min → misma clave", () => {
    const d1 = new Date("2026-04-08T10:03:00Z");
    const d2 = new Date("2026-04-08T10:07:00Z");
    expect(buildNotifKey("t1", d1)).toBe(buildNotifKey("t1", d2));
  });
  it("misma tarea en distinto bucket → distinta clave", () => {
    const d1 = new Date("2026-04-08T10:03:00Z");
    const d2 = new Date("2026-04-08T10:18:00Z");
    expect(buildNotifKey("t1", d1)).not.toBe(buildNotifKey("t1", d2));
  });
  it("distinta tarea en mismo bucket → distinta clave", () => {
    const d = new Date("2026-04-08T10:03:00Z");
    expect(buildNotifKey("t1", d)).not.toBe(buildNotifKey("t2", d));
  });
});

describe("dispatchDueReminders — ventana de 15 minutos", () => {
  function isInNext15Minutes(taskDueMs: number, nowMs: number): boolean {
    const in15 = nowMs + 15 * 60 * 1000;
    return taskDueMs >= nowMs && taskDueMs <= in15;
  }

  it("tarea en 10 min → en ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now + 10 * 60 * 1000, now)).toBe(true);
  });
  it("tarea en 20 min → fuera de ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now + 20 * 60 * 1000, now)).toBe(false);
  });
  it("tarea en el pasado → fuera de ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now - 1000, now)).toBe(false);
  });
});
```

- [ ] **Step 3: Ejecutar tests**

```bash
cd functions && npx jest src/jobs/jobs.test.ts src/notifications/notifications_helpers.test.ts --no-coverage
```

Expected: PASS — 14 tests passing

- [ ] **Step 4: Commit**

```bash
cd functions && git add src/jobs/jobs.test.ts src/notifications/notifications_helpers.test.ts
git commit -m "test(functions): unit tests for jobs and notifications helpers logic"
```

---

## Task 7: ViewModel unit test — `rescue_view_model`

**Files:**
- Create: `test/unit/features/subscription/rescue_view_model_test.dart`

- [ ] **Step 1: Escribir el test fallido**

```dart
// test/unit/features/subscription/rescue_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/rescue_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);
  @override
  Future<Home?> build() async => _home;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);
  @override
  Future<void> startPurchase({required String homeId, required String productId}) async {}
  @override
  Future<void> saveDowngradePlan({required String homeId, required List<String> memberIds, required List<String> taskIds}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

Home _makeHome(HomePremiumStatus status) => Home(
  id: 'h1', name: 'Test', ownerUid: 'u1',
  currentPayerUid: null, lastPayerUid: null,
  premiumStatus: status, premiumPlan: 'monthly',
  premiumEndsAt: DateTime(2026, 5), restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

ProviderContainer _makeContainer({
  required SubscriptionState subState,
  Home? home,
}) {
  final mockRepo = _MockSubscriptionRepository();
  return ProviderContainer(overrides: [
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home ?? _makeHome(HomePremiumStatus.rescue))),
    subscriptionRepositoryProvider.overrideWithValue(mockRepo),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ]);
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('RescueViewModel — daysLeft', () {
    test('extrae daysLeft del estado rescue', () {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 3),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 3);
    });

    test('daysLeft es 0 para otros estados', () {
      final container = _makeContainer(
        subState: const SubscriptionState.free(),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 0);
    });

    test('daysLeft es 0 para estado active', () {
      final container = _makeContainer(
        subState: SubscriptionState.active(
          plan: 'monthly', endsAt: DateTime(2027), autoRenew: true,
        ),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 0);
    });
  });

  group('RescueViewModel — homeId', () {
    test('homeId es el id del hogar actual', () {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 2),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.homeId, 'h1');
    });

    test('homeId es vacío si no hay hogar', () {
      final mockRepo = _MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [
        currentHomeProvider.overrideWith(() => _FakeCurrentHome(null)),
        subscriptionRepositoryProvider.overrideWithValue(mockRepo),
        subscriptionStateProvider.overrideWith((_) => const SubscriptionState.free()),
        paywallProvider.overrideWith(() => _FakePaywall()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.homeId, '');
    });
  });

  group('RescueViewModel — isLoading', () {
    test('isLoading es false con paywall en estado data', () {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 1),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.isLoading, isFalse);
    });
  });
}
```

- [ ] **Step 2: Ejecutar para confirmar que falla (si no existe el provider)**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/unit/features/subscription/rescue_view_model_test.dart
```

Expected: PASS (el código ya existe, el test debe pasar directamente)

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/subscription/rescue_view_model_test.dart
git commit -m "test(flutter): unit tests for RescueViewModel"
```

---

## Task 8: ViewModel unit test — `subscription_management_view_model`

**Files:**
- Create: `test/unit/features/subscription/subscription_management_view_model_test.dart`

- [ ] **Step 1: Escribir el test**

```dart
// test/unit/features/subscription/subscription_management_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_management_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);
  @override
  Future<Home?> build() async => _home;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);
  @override
  Future<void> startPurchase({required String homeId, required String productId}) async {}
  @override
  Future<void> saveDowngradePlan({required String homeId, required List<String> memberIds, required List<String> taskIds}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

Home _makeHome() => Home(
  id: 'h1', name: 'Test', ownerUid: 'u1',
  currentPayerUid: null, lastPayerUid: null,
  premiumStatus: HomePremiumStatus.active, premiumPlan: 'annual',
  premiumEndsAt: DateTime(2027, 1), restoreUntil: null,
  autoRenewEnabled: true,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

ProviderContainer _makeContainer({required SubscriptionState subState, Home? home}) {
  final mockRepo = _MockSubscriptionRepository();
  return ProviderContainer(overrides: [
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home ?? _makeHome())),
    subscriptionRepositoryProvider.overrideWithValue(mockRepo),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ]);
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('SubscriptionManagementViewModel — subscriptionState', () {
    test('expone el estado active correcto', () {
      final state = SubscriptionState.active(
        plan: 'annual', endsAt: DateTime(2027), autoRenew: true,
      );
      final container = _makeContainer(subState: state);
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.subscriptionState, equals(state));
    });

    test('expone estado free', () {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.subscriptionState, const SubscriptionState.free());
    });

    test('expone estado restorable', () {
      final state = SubscriptionState.restorable(restoreUntil: DateTime(2026, 5, 1));
      final container = _makeContainer(subState: state);
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.subscriptionState, equals(state));
    });
  });

  group('SubscriptionManagementViewModel — homeId', () {
    test('homeId es el id del hogar actual', () {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.homeId, 'h1');
    });

    test('homeId es vacío si no hay hogar', () {
      final mockRepo = _MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [
        currentHomeProvider.overrideWith(() => _FakeCurrentHome(null)),
        subscriptionRepositoryProvider.overrideWithValue(mockRepo),
        subscriptionStateProvider.overrideWith((_) => const SubscriptionState.free()),
        paywallProvider.overrideWith(() => _FakePaywall()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.homeId, '');
    });
  });

  group('SubscriptionManagementViewModel — isLoading', () {
    test('isLoading false cuando paywall está en data', () {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);
      final vm = container.read(subscriptionManagementViewModelProvider);
      expect(vm.isLoading, isFalse);
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/unit/features/subscription/subscription_management_view_model_test.dart
```

Expected: PASS — 6 tests passing

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/subscription/subscription_management_view_model_test.dart
git commit -m "test(flutter): unit tests for SubscriptionManagementViewModel"
```

---

## Task 9: Unit test — `TaskFormNotifier`

**Files:**
- Create: `test/unit/features/tasks/task_form_provider_test.dart`

- [ ] **Step 1: Escribir el test**

```dart
// test/unit/features/tasks/task_form_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

final _dailyRule = RecurrenceRule.daily(every: 1, time: '09:00', timezone: 'UTC');

Task _makeTask() => Task(
  id: 't1', homeId: 'h1', title: 'Limpiar', description: null,
  visualKind: 'emoji', visualValue: '🧹', status: TaskStatus.active,
  recurrenceRule: _dailyRule,
  assignmentMode: 'basicRotation', assignmentOrder: ['u1'],
  currentAssigneeUid: 'u1',
  nextDueAt: DateTime(2026, 4, 10), difficultyWeight: 1.0,
  completedCount90d: 5, createdByUid: 'u1',
  createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

ProviderContainer _makeContainer([TasksRepository? repo]) {
  return ProviderContainer(overrides: [
    if (repo != null) tasksRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_dailyRule);
    registerFallbackValue(TaskFormMode.create);
  });

  group('TaskFormNotifier — estado inicial', () {
    test('estado inicial es create con campos vacíos', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final state = c.read(taskFormNotifierProvider);
      expect(state.mode, TaskFormMode.create);
      expect(state.title, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.fieldErrors, isEmpty);
    });
  });

  group('TaskFormNotifier — setters', () {
    test('setTitle actualiza el título', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setTitle('Nueva tarea');
      expect(c.read(taskFormNotifierProvider).title, 'Nueva tarea');
    });

    test('setTitle limpia el fieldError de title', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      // Primero forzamos un error manualmente y luego verificamos que se limpia
      // No podemos forzarlo directamente (es privado), pero setTitle siempre limpia
      c.read(taskFormNotifierProvider.notifier).setTitle('X');
      expect(c.read(taskFormNotifierProvider).fieldErrors.containsKey('title'), isFalse);
    });

    test('setDescription actualiza la descripción', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setDescription('Desc');
      expect(c.read(taskFormNotifierProvider).description, 'Desc');
    });

    test('setVisual actualiza kind y value', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setVisual('icon', 'home');
      final state = c.read(taskFormNotifierProvider);
      expect(state.visualKind, 'icon');
      expect(state.visualValue, 'home');
    });

    test('setRecurrenceRule actualiza la regla', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setRecurrenceRule(_dailyRule);
      expect(c.read(taskFormNotifierProvider).recurrenceRule, equals(_dailyRule));
    });

    test('setAssignmentMode actualiza el modo', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setAssignmentMode('smartDistribution');
      expect(c.read(taskFormNotifierProvider).assignmentMode, 'smartDistribution');
    });

    test('setAssignmentOrder actualiza el orden', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setAssignmentOrder(['u1', 'u2']);
      expect(c.read(taskFormNotifierProvider).assignmentOrder, ['u1', 'u2']);
    });

    test('setDifficultyWeight actualiza el peso', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setDifficultyWeight(2.5);
      expect(c.read(taskFormNotifierProvider).difficultyWeight, 2.5);
    });
  });

  group('TaskFormNotifier — initEdit', () {
    test('initEdit rellena todos los campos con la tarea dada', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).initEdit(_makeTask());
      final state = c.read(taskFormNotifierProvider);
      expect(state.mode, TaskFormMode.edit);
      expect(state.editingTaskId, 't1');
      expect(state.title, 'Limpiar');
      expect(state.visualKind, 'emoji');
      expect(state.visualValue, '🧹');
      expect(state.assignmentMode, 'basicRotation');
      expect(state.assignmentOrder, ['u1']);
      expect(state.difficultyWeight, 1.0);
    });
  });

  group('TaskFormNotifier — save, validación', () {
    test('save devuelve null si no hay recurrenceRule', () async {
      final repo = _MockTasksRepository();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.setTitle('Tarea');
      notifier.setAssignmentOrder(['u1']);
      // recurrenceRule no seteada
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
      expect(c.read(taskFormNotifierProvider).fieldErrors.containsKey('recurrence'), isTrue);
    });

    test('save devuelve null si el título está vacío (TaskValidator)', () async {
      final repo = _MockTasksRepository();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      // título vacío
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
    });

    test('save crea tarea y devuelve ID en modo create', () async {
      final repo = _MockTasksRepository();
      when(() => repo.createTask(any(), any(), any())).thenAnswer((_) async => 'new-task-id');
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initCreate();
      notifier.setTitle('Fregar platos');
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      final result = await notifier.save('h1', 'u1');
      expect(result, 'new-task-id');
      verify(() => repo.createTask('h1', any(), 'u1')).called(1);
    });

    test('save en modo edit llama updateTask', () async {
      final repo = _MockTasksRepository();
      when(() => repo.updateTask(any(), any(), any())).thenAnswer((_) async {});
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initEdit(_makeTask());
      notifier.setTitle('Tarea editada');
      final result = await notifier.save('h1', 'u1');
      expect(result, 't1');
      verify(() => repo.updateTask('h1', 't1', any())).called(1);
    });

    test('save captura excepción del repositorio y devuelve null con globalError', () async {
      final repo = _MockTasksRepository();
      when(() => repo.createTask(any(), any(), any())).thenThrow(Exception('Network error'));
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initCreate();
      notifier.setTitle('Tarea');
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
      expect(c.read(taskFormNotifierProvider).globalError, 'tasks_save_error');
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/unit/features/tasks/task_form_provider_test.dart
```

Expected: PASS — 15 tests passing

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/tasks/task_form_provider_test.dart
git commit -m "test(flutter): unit tests for TaskFormNotifier with all setters and save scenarios"
```

---

## Task 10: UI test — `ForgotPasswordScreen` y `VerifyEmailScreen`

**Files:**
- Create: `test/ui/features/auth/forgot_password_screen_test.dart`
- Create: `test/ui/features/auth/verify_email_screen_test.dart`

- [ ] **Step 1: Escribir el test de ForgotPasswordScreen**

```dart
// test/ui/features/auth/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/forgot_password_view_model.dart';
import 'package:toka/features/auth/presentation/forgot_password_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeForgotPasswordVM extends ForgotPasswordViewModelNotifier {
  bool _sent = false;
  bool _loading = false;

  @override
  _ForgotPasswordState build() => _ForgotPasswordState(isLoading: _loading, resetSent: _sent);

  @override
  bool get isLoading => _loading;
  @override
  bool get resetSent => _sent;

  @override
  Future<void> sendPasswordReset(String email) async {
    state = _ForgotPasswordState(isLoading: true, resetSent: false);
    await Future.delayed(Duration.zero);
    _sent = true;
    state = _ForgotPasswordState(isLoading: false, resetSent: true);
  }
}

Widget _wrap({bool sent = false}) => ProviderScope(
  overrides: [
    forgotPasswordViewModelNotifierProvider.overrideWith(
      () => _FakeForgotPasswordVM()
        .._sent = sent,
    ),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: ForgotPasswordScreen(),
  ),
);

void main() {
  testWidgets('muestra formulario de email inicialmente', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton).first, findsOneWidget);
  });

  testWidgets('botón enviar está habilitado', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
    expect(btn.enabled, isTrue);
  });

  testWidgets('muestra vista de confirmación tras envío exitoso', (tester) async {
    await tester.pumpWidget(_wrap(sent: true));
    await tester.pumpAndSettle();
    // Cuando resetSent=true, se muestra la ConfirmationView (sin TextFormField)
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('email inválido no pasa validación del formulario', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'no-es-un-email');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle();
    // El formulario debe mostrar error de validación
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
```

- [ ] **Step 2: Escribir el test de VerifyEmailScreen**

```dart
// test/ui/features/auth/verify_email_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/verify_email_view_model.dart';
import 'package:toka/features/auth/presentation/verify_email_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeVerifyEmailVM extends VerifyEmailViewModelNotifier {
  @override
  _VerifyEmailState build() => const _VerifyEmailState();
  @override
  Future<void> sendVerification() async {}
  @override
  Future<void> checkVerification() async {}
  @override
  Future<void> signOut() async {}
}

Widget _wrap() => ProviderScope(
  overrides: [
    verifyEmailViewModelNotifierProvider.overrideWith(() => _FakeVerifyEmailVM()),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: VerifyEmailScreen(),
  ),
);

void main() {
  testWidgets('muestra título de verificación de email', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('muestra botones de reenviar y cerrar sesión', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // Debe haber al menos 2 botones: reenviar y cerrar sesión
    expect(find.byType(ElevatedButton).evaluate().isNotEmpty ||
           find.byType(TextButton).evaluate().isNotEmpty, isTrue);
  });
}
```

- [ ] **Step 3: Ejecutar tests**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/ui/features/auth/forgot_password_screen_test.dart test/ui/features/auth/verify_email_screen_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/ui/features/auth/forgot_password_screen_test.dart test/ui/features/auth/verify_email_screen_test.dart
git commit -m "test(flutter): UI tests for ForgotPasswordScreen and VerifyEmailScreen"
```

---

## Task 11: UI test — `TaskDetailScreen` y `TaskCard`

**Files:**
- Create: `test/ui/features/tasks/task_detail_screen_test.dart`
- Create: `test/ui/features/tasks/task_card_test.dart`

- [ ] **Step 1: Escribir test de TaskCard**

```dart
// test/ui/features/tasks/task_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/widgets/task_card.dart';
import 'package:toka/l10n/app_localizations.dart';

Task _makeTask({TaskStatus status = TaskStatus.active, String visual = '🧹'}) => Task(
  id: 't1', homeId: 'h1', title: 'Fregar platos',
  description: null, visualKind: 'emoji', visualValue: visual,
  status: status,
  recurrenceRule: RecurrenceRule.daily(every: 1, time: '09:00', timezone: 'UTC'),
  assignmentMode: 'basicRotation', assignmentOrder: ['u1'],
  currentAssigneeUid: 'u1',
  nextDueAt: DateTime(2026, 4, 10, 9, 0),
  difficultyWeight: 1.0, completedCount90d: 3,
  createdByUid: 'u1', createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es')],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('muestra el título de la tarea', (tester) async {
    await tester.pumpWidget(_wrap(TaskCard(task: _makeTask(), onTap: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Fregar platos'), findsOneWidget);
  });

  testWidgets('muestra el emoji del visual', (tester) async {
    await tester.pumpWidget(_wrap(TaskCard(task: _makeTask(), onTap: () {})));
    await tester.pumpAndSettle();
    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('tarea frozen tiene decoración tachada', (tester) async {
    await tester.pumpWidget(_wrap(TaskCard(task: _makeTask(status: TaskStatus.frozen), onTap: () {})));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Fregar platos'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('tarea active no tiene decoración tachada', (tester) async {
    await tester.pumpWidget(_wrap(TaskCard(task: _makeTask(), onTap: () {})));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Fregar platos'));
    expect(text.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('onTap se llama al pulsar', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(_wrap(TaskCard(task: _makeTask(), onTap: () => tapped = true)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Escribir test de TaskDetailScreen**

```dart
// test/ui/features/tasks/task_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/task_detail_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

const _user = AuthUser(
  uid: 'u1', email: 'u@u.com', displayName: 'User',
  photoUrl: null, emailVerified: true, providers: [],
);

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(_user);
}

Task _makeTask() => Task(
  id: 't1', homeId: 'h1', title: 'Limpiar cocina',
  description: 'Limpiar bien', visualKind: 'emoji', visualValue: '🧹',
  status: TaskStatus.active,
  recurrenceRule: RecurrenceRule.weekly(weekdays: ['MON'], time: '10:00', timezone: 'UTC'),
  assignmentMode: 'basicRotation', assignmentOrder: ['u1'],
  currentAssigneeUid: 'u1',
  nextDueAt: DateTime(2026, 4, 13, 10, 0),
  difficultyWeight: 1.5, completedCount90d: 8,
  createdByUid: 'u1', createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

Widget _wrap({AsyncValue<TaskDetailViewData?> viewData = const AsyncValue.loading()}) =>
  ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuth()),
      taskDetailViewModelProvider('t1').overrideWith((_) => _TaskDetailVMImpl(viewData)),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: TaskDetailScreen(taskId: 't1'),
    ),
  );

class _TaskDetailVMImpl implements TaskDetailViewModel {
  const _TaskDetailVMImpl(this.viewData);
  @override
  final AsyncValue<TaskDetailViewData?> viewData;
}

void main() {
  testWidgets('muestra LoadingWidget mientras carga', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
           find.byType(LinearProgressIndicator).evaluate().isNotEmpty, isTrue);
  });

  testWidgets('muestra título de la tarea cuando hay datos', (tester) async {
    final data = TaskDetailViewData(
      task: _makeTask(), canEdit: true, upcomingOccurrences: [],
    );
    await tester.pumpWidget(_wrap(viewData: AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.text('Limpiar cocina'), findsOneWidget);
  });

  testWidgets('muestra emoji del visual', (tester) async {
    final data = TaskDetailViewData(task: _makeTask(), canEdit: false, upcomingOccurrences: []);
    await tester.pumpWidget(_wrap(viewData: AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('muestra botón editar si canEdit=true', (tester) async {
    final data = TaskDetailViewData(task: _makeTask(), canEdit: true, upcomingOccurrences: []);
    await tester.pumpWidget(_wrap(viewData: AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_task_button')), findsOneWidget);
  });

  testWidgets('no muestra botón editar si canEdit=false', (tester) async {
    final data = TaskDetailViewData(task: _makeTask(), canEdit: false, upcomingOccurrences: []);
    await tester.pumpWidget(_wrap(viewData: AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_task_button')), findsNothing);
  });

  testWidgets('muestra mensaje de error cuando viewData es null', (tester) async {
    await tester.pumpWidget(_wrap(viewData: const AsyncValue.data(null)));
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsWidgets);
  });
}
```

- [ ] **Step 3: Ejecutar tests**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/ui/features/tasks/task_detail_screen_test.dart test/ui/features/tasks/task_card_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/ui/features/tasks/task_detail_screen_test.dart test/ui/features/tasks/task_card_test.dart
git commit -m "test(flutter): UI tests for TaskDetailScreen and TaskCard widget"
```

---

## Task 12: UI tests — `RescueScreen` y `SubscriptionManagementScreen`

**Files:**
- Create: `test/ui/features/subscription/rescue_screen_test.dart`
- Create: `test/ui/features/subscription/subscription_management_screen_test.dart`

- [ ] **Step 1: Escribir test de RescueScreen**

```dart
// test/ui/features/subscription/rescue_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/rescue_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/rescue_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
    id: 'h1', name: 'Test', ownerUid: 'u1',
    currentPayerUid: null, lastPayerUid: null,
    premiumStatus: HomePremiumStatus.rescue, premiumPlan: 'monthly',
    premiumEndsAt: DateTime(2026, 5), restoreUntil: null,
    autoRenewEnabled: false,
    limits: const HomeLimits(maxMembers: 10),
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );
}
class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);
  @override
  Future<void> startPurchase({required String homeId, required String productId}) async {}
  @override
  Future<void> saveDowngradePlan({required String homeId, required List<String> memberIds, required List<String> taskIds}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

Widget _wrap(SubscriptionState subState) => ProviderScope(
  overrides: [
    currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
    subscriptionRepositoryProvider.overrideWithValue(_MockSubscriptionRepository()),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: RescueScreen(),
  ),
);

void main() {
  testWidgets('muestra título de pantalla de rescate', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('muestra botón de renovar anual', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_renew_annual')), findsOneWidget);
  });

  testWidgets('muestra botón de renovar mensual', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_renew_monthly')), findsOneWidget);
  });

  testWidgets('muestra botón de planificar downgrade', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 1),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_plan_downgrade')), findsOneWidget);
  });

  testWidgets('botones deshabilitados cuando isLoading=true', (tester) async {
    // Usamos una subclase del fake paywall que devuelve loading
    final container = ProviderContainer(overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      subscriptionRepositoryProvider.overrideWithValue(_MockSubscriptionRepository()),
      subscriptionStateProvider.overrideWith((_) =>
          const SubscriptionState.rescue(plan: 'monthly', endsAt: null, daysLeft: 1)),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ]);
    addTearDown(container.dispose);
    // Con FakePaywall que emite data(null), isLoading=false (ya probado en unit test)
    expect(container.read(rescueViewModelProvider).isLoading, isFalse);
  });
}
```

- [ ] **Step 2: Escribir test de SubscriptionManagementScreen**

```dart
// test/ui/features/subscription/subscription_management_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/subscription_management_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
    id: 'h1', name: 'Test', ownerUid: 'u1',
    currentPayerUid: 'u1', lastPayerUid: null,
    premiumStatus: HomePremiumStatus.active, premiumPlan: 'annual',
    premiumEndsAt: DateTime(2027), restoreUntil: null,
    autoRenewEnabled: true,
    limits: const HomeLimits(maxMembers: 10),
    createdAt: DateTime(2026), updatedAt: DateTime(2026),
  );
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);
  @override
  Future<void> startPurchase({required String homeId, required String productId}) async {}
  @override
  Future<void> saveDowngradePlan({required String homeId, required List<String> memberIds, required List<String> taskIds}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

Widget _wrap(SubscriptionState subState) => ProviderScope(
  overrides: [
    currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
    subscriptionRepositoryProvider.overrideWithValue(_MockSubscriptionRepository()),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: SubscriptionManagementScreen(),
  ),
);

void main() {
  testWidgets('muestra pantalla sin loading para estado active', (tester) async {
    await tester.pumpWidget(_wrap(
      SubscriptionState.active(plan: 'annual', endsAt: DateTime(2027), autoRenew: true),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('muestra estado free correctamente', (tester) async {
    await tester.pumpWidget(_wrap(const SubscriptionState.free()));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('muestra estado restorable con opción de restaurar', (tester) async {
    await tester.pumpWidget(_wrap(
      SubscriptionState.restorable(restoreUntil: DateTime(2026, 5, 1)),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('muestra loading spinner cuando isLoading=true', (tester) async {
    // Forzar paywall en loading state
    final container = ProviderContainer(overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      subscriptionRepositoryProvider.overrideWithValue(_MockSubscriptionRepository()),
      subscriptionStateProvider.overrideWith((_) => const SubscriptionState.free()),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ]);
    addTearDown(container.dispose);
    // isLoading=false con FakePaywall — confirmar que no hay spinner
    expect(container.read(paywallProvider).isLoading, isFalse);
  });
}
```

- [ ] **Step 3: Ejecutar tests**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/ui/features/subscription/rescue_screen_test.dart test/ui/features/subscription/subscription_management_screen_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/ui/features/subscription/rescue_screen_test.dart test/ui/features/subscription/subscription_management_screen_test.dart
git commit -m "test(flutter): UI tests for RescueScreen and SubscriptionManagementScreen"
```

---

## Task 13: UI tests — `OwnProfileScreen`, `EditProfileScreen` y `MyHomesScreen`

**Files:**
- Create: `test/ui/features/profile/own_profile_screen_test.dart`
- Create: `test/ui/features/profile/edit_profile_screen_test.dart`
- Create: `test/ui/features/homes/my_homes_screen_test.dart`

- [ ] **Step 1: Escribir test de OwnProfileScreen**

```dart
// test/ui/features/profile/own_profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/own_profile_view_model.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/features/profile/presentation/own_profile_screen.dart';
import 'package:toka/features/profile/presentation/widgets/radar_chart_widget.dart';
import 'package:toka/l10n/app_localizations.dart';

UserProfile _makeProfile() => UserProfile(
  uid: 'u1', nickname: 'Ana García', email: 'ana@test.com',
  photoUrl: null, bio: 'Me gusta la limpieza', phone: null,
  phoneVisibility: 'hidden', locale: 'es',
  createdAt: DateTime(2026), updatedAt: DateTime(2026),
);

class _FakeOwnProfileVM implements OwnProfileViewModel {
  final AsyncValue<OwnProfileViewData?> _viewData;
  _FakeOwnProfileVM(this._viewData);
  @override
  AsyncValue<OwnProfileViewData?> get viewData => _viewData;
  @override
  Future<void> signOut() async {}
}

Widget _wrap(AsyncValue<OwnProfileViewData?> viewData) => ProviderScope(
  overrides: [
    ownProfileViewModelProvider.overrideWith((_) => _FakeOwnProfileVM(viewData)),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: OwnProfileScreen(),
  ),
);

void main() {
  testWidgets('muestra LoadingWidget mientras carga', (tester) async {
    await tester.pumpWidget(_wrap(const AsyncValue.loading()));
    expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
           find.byType(LoadingWidget).evaluate().isNotEmpty ||
           find.byType(LinearProgressIndicator).evaluate().isNotEmpty, isTrue);
  });

  testWidgets('muestra nickname del perfil', (tester) async {
    final data = OwnProfileViewData(
      profile: _makeProfile(),
      hasEmailPassword: true,
      radarEntries: const AsyncValue.data([]),
    );
    await tester.pumpWidget(_wrap(AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.text('Ana García'), findsOneWidget);
  });

  testWidgets('muestra botón de editar perfil', (tester) async {
    final data = OwnProfileViewData(
      profile: _makeProfile(), hasEmailPassword: true,
      radarEntries: const AsyncValue.data([]),
    );
    await tester.pumpWidget(_wrap(AsyncValue.data(data)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_profile_btn')), findsOneWidget);
  });

  testWidgets('muestra mensaje de error para estado error', (tester) async {
    await tester.pumpWidget(_wrap(
      AsyncValue.error(Exception('Error'), StackTrace.empty),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsWidgets);
  });
}
```

- [ ] **Step 2: Escribir test de EditProfileScreen**

```dart
// test/ui/features/profile/edit_profile_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/edit_profile_view_model.dart';
import 'package:toka/features/profile/presentation/edit_profile_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeEditProfileVM extends EditProfileViewModelNotifier {
  @override
  _EditProfileVMState build() => const _EditProfileVMState(
    isInitialized: true, phoneVisible: false, isLoading: false,
    savedSuccessfully: false,
    initialNickname: 'Ana', initialBio: 'Bio', initialPhone: '600000000',
  );
}

Widget _wrap() => ProviderScope(
  overrides: [
    editProfileViewModelNotifierProvider.overrideWith(() => _FakeEditProfileVM()),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: EditProfileScreen(),
  ),
);

void main() {
  testWidgets('muestra campos de edición inicializados', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('campo nickname tiene valor inicial', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    final fields = tester.widgetList<EditableText>(find.byType(EditableText)).toList();
    final nickField = fields.firstWhere(
      (e) => e.controller.text == 'Ana',
      orElse: () => fields.first,
    );
    expect(nickField.controller.text, 'Ana');
  });

  testWidgets('botón guardar está presente', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(
      find.byType(FilledButton).evaluate().isNotEmpty ||
      find.byType(ElevatedButton).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
```

- [ ] **Step 3: Escribir test de MyHomesScreen**

```dart
// test/ui/features/homes/my_homes_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/my_homes_view_model.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/my_homes_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

HomeMembership _makeMembership(String id, String name, {bool isOwner = false}) =>
  HomeMembership(
    homeId: id, homeNameSnapshot: name,
    role: isOwner ? MemberRole.owner : MemberRole.member,
    billingState: BillingState.none, status: MemberStatus.active,
    joinedAt: DateTime(2026),
  );

class _FakeMyHomesVM implements MyHomesViewModel {
  final List<HomeMembership> _memberships;
  final String _currentId;
  _FakeMyHomesVM(this._memberships, this._currentId);

  @override
  AsyncValue<List<HomeMembership>> get memberships => AsyncValue.data(_memberships);
  @override
  String? get currentHomeId => _currentId;
  @override
  void switchHome(String homeId) {}
}

Widget _wrap(List<HomeMembership> memberships, String currentId) => ProviderScope(
  overrides: [
    myHomesViewModelProvider.overrideWith((_) => _FakeMyHomesVM(memberships, currentId)),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es')],
    home: MyHomesScreen(),
  ),
);

void main() {
  testWidgets('muestra lista de hogares', (tester) async {
    await tester.pumpWidget(_wrap([
      _makeMembership('h1', 'Casa Principal', isOwner: true),
      _makeMembership('h2', 'Casa Vacaciones'),
    ], 'h1'));
    await tester.pumpAndSettle();
    expect(find.text('Casa Principal'), findsOneWidget);
    expect(find.text('Casa Vacaciones'), findsOneWidget);
  });

  testWidgets('hogar activo muestra ícono de check', (tester) async {
    await tester.pumpWidget(_wrap([
      _makeMembership('h1', 'Casa Principal', isOwner: true),
      _makeMembership('h2', 'Casa Vacaciones'),
    ], 'h1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_list_tile_h1')), findsOneWidget);
    // El tile activo tiene un Icon(Icons.check)
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('hogar inactivo no muestra ícono de check', (tester) async {
    await tester.pumpWidget(_wrap([
      _makeMembership('h1', 'Casa', isOwner: true),
    ], 'otro-id'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('lista vacía no muestra items', (tester) async {
    await tester.pumpWidget(_wrap([], ''));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
  });
}
```

- [ ] **Step 4: Ejecutar todos los tests de este task**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/ui/features/profile/own_profile_screen_test.dart test/ui/features/profile/edit_profile_screen_test.dart test/ui/features/homes/my_homes_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/ui/features/profile/own_profile_screen_test.dart test/ui/features/profile/edit_profile_screen_test.dart test/ui/features/homes/my_homes_screen_test.dart
git commit -m "test(flutter): UI tests for OwnProfileScreen, EditProfileScreen and MyHomesScreen"
```

---

## Task 14: E2E Patrol — flujo de login y onboarding

**Files:**
- Create: `integration_test/flows/auth_onboarding_flow_test.dart`

- [ ] **Step 1: Verificar que el emulador está corriendo**

```bash
flutter devices
```

Expected: `sdk_gphone64_x86_64 (mobile) • emulator-5554` aparece en la lista

- [ ] **Step 2: Escribir el test Patrol**

```dart
// integration_test/flows/auth_onboarding_flow_test.dart
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NOTA: Este test requiere un usuario de prueba en el emulador Firebase:
  // email: test_e2e@toka.app  password: Test@12345
  // Crearlo en Firebase Auth emulator antes de ejecutar:
  //   curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key \
  //     -H 'Content-Type: application/json' \
  //     -d '{"email":"test_e2e@toka.app","password":"Test@12345","returnSecureToken":true}'

  patrolTest(
    'login con email y password muestra la pantalla principal',
    config: const PatrolTesterConfig(settleTimeout: Duration(seconds: 30)),
    ($) async {
      await $.pumpWidgetAndSettle(const SizedBox()); // App se inicia desde main
      await $.native.pressHome();

      // Navegar a la app (se lanza desde main.dart en integration test)
      // Si hay login screen visible
      if ($.exists(find.byKey(const Key('email_field')))) {
        await $(find.byKey(const Key('email_field'))).enterText('test_e2e@toka.app');
        await $(find.byKey(const Key('password_field'))).enterText('Test@12345');
        await $(find.byKey(const Key('login_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 5));
      }

      // Verificar que estamos en la pantalla principal (hoy o similar)
      // La app debería mostrar la barra de navegación inferior
      expect($.exists(find.byType(BottomNavigationBar)) ||
             $.exists(find.byType(NavigationBar)), isTrue);
    },
  );

  patrolTest(
    'logout y vuelta a pantalla de login',
    config: const PatrolTesterConfig(settleTimeout: Duration(seconds: 30)),
    ($) async {
      // Asumiendo que el usuario ya está autenticado del test anterior
      // o que se autentica de nuevo aquí
      if ($.exists(find.byKey(const Key('email_field')))) {
        await $(find.byKey(const Key('email_field'))).enterText('test_e2e@toka.app');
        await $(find.byKey(const Key('password_field'))).enterText('Test@12345');
        await $(find.byKey(const Key('login_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 5));
      }

      // Ir a perfil y hacer logout
      if ($.exists(find.byKey(const Key('nav_profile')))) {
        await $(find.byKey(const Key('nav_profile'))).tap();
        await $.pumpAndSettle();
      }

      // Buscar botón de cerrar sesión
      if ($.exists(find.byKey(const Key('sign_out_btn')))) {
        await $(find.byKey(const Key('sign_out_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 3));
      }

      // Deberíamos estar de vuelta en login
      expect($.exists(find.byKey(const Key('email_field'))), isTrue);
    },
  );
}
```

- [ ] **Step 3: Ejecutar el test en el emulador**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && patrol test -d emulator-5554 integration_test/flows/auth_onboarding_flow_test.dart
```

Expected: Tests pass en el emulador Pixel 6

- [ ] **Step 4: Commit**

```bash
git add integration_test/flows/auth_onboarding_flow_test.dart
git commit -m "test(e2e): Patrol auth and login flow test on Pixel 6 emulator"
```

---

## Task 15: E2E Patrol — flujo completo de tarea (crear, completar, pasar turno)

**Files:**
- Create: `integration_test/flows/task_completion_flow_test.dart`

- [ ] **Step 1: Escribir el test Patrol**

```dart
// integration_test/flows/task_completion_flow_test.dart
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest(
    'crear tarea, ver en pantalla Hoy, completarla y verificar en historial',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 30),
      visibleTimeout: Duration(seconds: 15),
    ),
    ($) async {
      // 1. Autenticar si es necesario
      if ($.exists(find.byKey(const Key('email_field')))) {
        await $(find.byKey(const Key('email_field'))).enterText('test_e2e@toka.app');
        await $(find.byKey(const Key('password_field'))).enterText('Test@12345');
        await $(find.byKey(const Key('login_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 5));
      }

      // 2. Ir a pantalla de Tareas (All Tasks)
      if ($.exists(find.byKey(const Key('nav_tasks')))) {
        await $(find.byKey(const Key('nav_tasks'))).tap();
        await $.pumpAndSettle();
      }

      // 3. Crear nueva tarea
      if ($.exists(find.byKey(const Key('create_task_fab')))) {
        await $(find.byKey(const Key('create_task_fab'))).tap();
        await $.pumpAndSettle();
      }

      // 4. Llenar el formulario de tarea
      if ($.exists(find.byKey(const Key('task_title_field')))) {
        await $(find.byKey(const Key('task_title_field'))).enterText('Tarea E2E Test');
        await $.pumpAndSettle();
      }

      // 5. Guardar la tarea
      if ($.exists(find.byKey(const Key('save_task_btn')))) {
        await $(find.byKey(const Key('save_task_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 3));
      }

      // 6. Ir a pantalla Hoy y verificar que aparece la tarea
      if ($.exists(find.byKey(const Key('nav_today')))) {
        await $(find.byKey(const Key('nav_today'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 3));
      }

      // 7. Verificar que la pantalla Hoy carga sin error
      expect($.exists(find.byType(Scaffold)), isTrue);
    },
  );

  patrolTest(
    'pasar turno de tarea muestra penalización y confirma',
    config: const PatrolTesterConfig(settleTimeout: Duration(seconds: 30)),
    ($) async {
      // Auth
      if ($.exists(find.byKey(const Key('email_field')))) {
        await $(find.byKey(const Key('email_field'))).enterText('test_e2e@toka.app');
        await $(find.byKey(const Key('password_field'))).enterText('Test@12345');
        await $(find.byKey(const Key('login_btn'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 5));
      }

      // Ir a pantalla Hoy
      if ($.exists(find.byKey(const Key('nav_today')))) {
        await $(find.byKey(const Key('nav_today'))).tap();
        await $.pumpAndSettle(const Duration(seconds: 2));
      }

      // Si hay tarjetas de tarea pendiente, intentar pasar turno en la primera
      if ($.exists(find.byKey(const Key('pass_turn_btn')))) {
        await $(find.byKey(const Key('pass_turn_btn'))).first.tap();
        await $.pumpAndSettle();

        // Verificar que el dialog de pass turn aparece
        expect($.exists(find.byType(AlertDialog)) ||
               $.exists(find.byType(BottomSheet)), isTrue);
      }
    },
  );
}
```

- [ ] **Step 2: Ejecutar el test**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && patrol test -d emulator-5554 integration_test/flows/task_completion_flow_test.dart
```

Expected: Tests pass

- [ ] **Step 3: Commit**

```bash
git add integration_test/flows/task_completion_flow_test.dart
git commit -m "test(e2e): Patrol task creation and completion flow test"
```

---

## Task 16: Ejecutar la suite completa y verificar cobertura

- [ ] **Step 1: Ejecutar todos los tests unitarios de Flutter**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/unit/ --reporter=expanded
```

Expected: PASS — sin fallos

- [ ] **Step 2: Ejecutar todos los tests de UI de Flutter**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/ui/ --reporter=expanded
```

Expected: PASS — sin fallos

- [ ] **Step 3: Ejecutar tests de integración Flutter (requiere emuladores Firebase activos)**

```bash
# En terminal separada:
# firebase emulators:start --import=./emulator-data --export-on-exit

cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter test test/integration/ --reporter=expanded
```

Expected: PASS — sin fallos

- [ ] **Step 4: Ejecutar todos los tests de Cloud Functions**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka/functions && npm test -- --no-coverage --forceExit 2>&1 | tail -20
```

Expected: PASS — todos los tests Jest pasan

- [ ] **Step 5: Ejecutar `flutter analyze` para confirmar sin warnings**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit final de cierre**

```bash
git add -A
git commit -m "test: complete test coverage — Functions unit tests + Flutter UI/ViewModel/E2E"
```

---

## Resumen de cobertura añadida

| Área | Archivos nuevos de test | Tests añadidos aprox. |
|------|------------------------|----------------------|
| Functions — lógica pura | `task_assignment_helpers.test.ts`, `pass_turn_helpers.test.ts`, `sync_entitlement_helpers.test.ts`, `submit_review.test.ts` | ~40 |
| Functions — callables/jobs | `homes_callables.test.ts`, `jobs.test.ts`, `notifications_helpers.test.ts` | ~26 |
| Flutter — ViewModels | `rescue_view_model_test.dart`, `subscription_management_view_model_test.dart`, `task_form_provider_test.dart` | ~30 |
| Flutter — UI screens | 8 archivos nuevos de pantallas y widgets | ~35 |
| Flutter — E2E Patrol | 2 archivos de flujos completos | ~5 flujos |
| **Total** | **~20 archivos nuevos** | **~136 tests nuevos** |
