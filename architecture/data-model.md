# Modelo de datos Firestore — Toka

Referencia completa de colecciones, documentos y campos.

---

## app_config/languages (PÚBLICA, solo lectura)

Colección pública consultada en onboarding y ajustes de idioma.

```
app_config/languages/{code}
{
  code: string,          // "es", "en", "ro"
  name: string,          // "Español", "English", "Română"
  flag: string,          // emoji "🇪🇸"
  arb_key: string,       // "app_es" → corresponde a app_es.arb
  enabled: boolean,
  sort_order: number
}
```

Security Rules: `allow read: if true;` (pública). `allow write: if false;`

---

## users/{uid}

```
{
  displayName: string,
  nickname: string,
  photoUrl: string | null,
  phoneNumber: string | null,
  phoneVisibility: "sameHomeMembers" | "hidden",
  bio: string | null,
  locale: string,                      // "es", "en", "ro"
  authProviders: string[],             // ["google.com", "password"]
  baseHomeSlots: number,               // siempre 2
  lifetimeUnlockedHomeSlots: number,   // 0-3
  homeSlotCap: number,                 // baseHomeSlots + lifetimeUnlockedHomeSlots (2-5)
  lastSelectedHomeId: string | null,
  createdAt: Timestamp,
  lastSeenAt: Timestamp
}
```

### users/{uid}/memberships/{homeId}

```
{
  homeId: string,
  role: "owner" | "admin" | "member" | "frozen",
  billingState: "currentPayer" | "formerPayer" | "none",
  status: "active" | "frozen",
  joinedAt: Timestamp,
  leftAt: Timestamp | null,
  homeNameSnapshot: string
}
```

### users/{uid}/slotLedger/{unlockId}

```
{
  sourceType: "premium_purchase",
  sourceChargeId: string,
  unlockedAt: Timestamp,
  validForUnlock: boolean,
  slotNumber: number    // 1, 2 o 3
}
```

---

## homes/{homeId}

```
{
  name: string,
  ownerUid: string,
  currentPayerUid: string | null,
  lastPayerUid: string | null,
  premiumStatus: "free" | "active" | "cancelled_pending_end" | "rescue" | "expired_free" | "restorable" | "purged",
  premiumPlan: "monthly" | "annual" | null,
  premiumEndsAt: Timestamp | null,
  restoreUntil: Timestamp | null,
  autoRenewEnabled: boolean,
  limits: {
    maxMembers: number,
    maxTasks: number,
    maxAdmins: number,
    maxRecurringTasks: number,
    historyDays: number
  },
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### homes/{homeId}/views/dashboard

```
{
  activeTasksPreview: TaskPreview[],    // max 50, ordenadas para "Hoy"
  doneTasksPreview: TaskPreview[],      // últimas 20 completadas hoy
  counters: {
    totalActiveTasks: number,
    totalMembers: number,
    tasksDueToday: number,
    tasksDoneToday: number
  },
  memberPreview: MemberPreview[],
  premiumFlags: {
    isPremium: boolean,
    showAds: boolean,
    canUseSmartDistribution: boolean,
    canUseVacations: boolean,
    canUseReviews: boolean
  },
  adFlags: { showBanner: boolean, bannerUnit: string },
  rescueFlags: { isInRescue: boolean, daysLeft: number | null },
  updatedAt: Timestamp
}
```

### homes/{homeId}/members/{uid}

```
{
  uid: string,
  role: "owner" | "admin" | "member" | "frozen",
  billingState: "currentPayer" | "formerPayer" | "none",
  status: "active" | "frozen",
  joinedAt: Timestamp,
  freezeEffectiveAt: Timestamp | null,
  completions60d: number,
  completedCount: number,
  passedCount: number,
  complianceRate: number,        // completedCount / (completedCount + passedCount)
  onTimeRate: number,
  avgReviewScore: number | null,
  currentStreak: number,
  lastCompletedAt: Timestamp | null,
  lastActiveAt: Timestamp | null
}
```

### homes/{homeId}/tasks/{taskId}

```
{
  title: string,
  description: string | null,
  visualKind: "icon" | "emoji",
  visualValue: string,
  status: "active" | "frozen" | "deleted",
  recurrenceType: "hourly" | "daily" | "weekly" | "monthly" | "yearly",
  recurrenceRule: RecurrenceRule,
  assignmentMode: "basicRotation" | "smartDistribution",
  assignmentOrder: string[],          // lista de UIDs en orden de rotación
  currentAssigneeUid: string | null,
  nextDueAt: Timestamp,
  difficultyWeight: number,           // 1-5, default 3
  completedCount90d: number,
  createdByUid: string,
  updatedAt: Timestamp,
  createdAt: Timestamp
}

RecurrenceRule (ejemplos):
// hourly
{ kind: "hourly", every: 2, startTime: "08:00", endTime: "20:00", timezone: "Europe/Madrid" }
// daily
{ kind: "daily", every: 1, time: "09:00", timezone: "Europe/Madrid" }
// weekly
{ kind: "weekly", weekdays: ["MON","THU"], time: "19:00", timezone: "Europe/Madrid" }
// monthly (día fijo)
{ kind: "monthly", mode: "fixedDay", day: 15, time: "10:00", timezone: "Europe/Madrid" }
// monthly (semana + día)
{ kind: "monthly", mode: "nthWeekday", weekOfMonth: 2, weekday: "THU", time: "19:00", timezone: "Europe/Madrid" }
// yearly (fecha fija)
{ kind: "yearly", mode: "fixedDate", month: 3, day: 21, time: "10:00", timezone: "Europe/Madrid" }
// yearly (patrón)
{ kind: "yearly", mode: "nthWeekday", month: 3, weekOfMonth: 3, weekday: "SUN", time: "10:00", timezone: "Europe/Madrid" }
```

### homes/{homeId}/taskEvents/{eventId}

```
{
  eventType: "completed" | "passed",
  taskId: string,
  taskTitleSnapshot: string,
  taskVisualSnapshot: { kind: string, value: string },
  actorUid: string,
  performerUid: string | null,      // para completed
  fromUid: string | null,           // para passed
  toUid: string | null,             // para passed
  reason: string | null,            // motivo opcional del pase
  penaltyApplied: boolean,
  complianceBefore: number | null,
  complianceAfter: number | null,
  completedAt: Timestamp | null,
  createdAt: Timestamp
}
```

### homes/{homeId}/taskEvents/{eventId}/reviews/{uid}

```
{
  score: number,       // 1-10
  note: string | null, // máx 300 chars
  byUid: string,
  createdAt: Timestamp
}
```

### homes/{homeId}/memberTaskStats/{uid_taskId}

```
{
  uid: string,
  taskId: string,
  avgScore: number | null,
  reviewCount: number,
  completionCount: number,
  lastReviewedAt: Timestamp | null
}
```

### homes/{homeId}/downgrade/current

```
{
  selectedMemberIds: string[],
  selectedTaskIds: string[],
  selectedAdminUid: string | null,
  scheduledFreezePayer: boolean,
  decidedAt: Timestamp | null,
  mode: "manual" | "auto"
}
```

### homes/{homeId}/subscriptions/history/{chargeId}

```
{
  provider: "apple" | "google" | "stripe",
  plan: "monthly" | "annual",
  status: "active" | "cancelled" | "refunded" | "failed",
  premiumEndsAt: Timestamp,
  autoRenewEnabled: boolean,
  validForUnlock: boolean,
  createdAt: Timestamp
}
```

### homes/{homeId}/invitations/{inviteId}

```
{
  code: string,
  invitedByUid: string,
  expiresAt: Timestamp,
  targetEmail: string | null,
  status: "pending" | "accepted" | "expired" | "cancelled"
}
```

### homes/{homeId}/system/meta

```
{
  schemaVersion: number,
  lastAggregateRun: Timestamp | null,
  lastPremiumSyncAt: Timestamp | null,
  lastReminderRun: Timestamp | null
}
```

---

## Índices compuestos requeridos (firestore.indexes.json)

| Colección              | Campos                                | Orden         |
| ---------------------- | ------------------------------------- | ------------- |
| homes/{id}/tasks       | status, nextDueAt                     | ASC, ASC      |
| homes/{id}/tasks       | currentAssigneeUid, status, nextDueAt | ASC, ASC, ASC |
| homes/{id}/taskEvents  | createdAt                             | DESC          |
| homes/{id}/taskEvents  | taskId, createdAt                     | ASC, DESC     |
| homes/{id}/invitations | status, expiresAt                     | ASC, ASC      |
| users/{id}/memberships | status                                | ASC           |
