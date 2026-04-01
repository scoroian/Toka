# Spec-11: Recordatorios y notificaciones push

**Dependencias previas:** Spec-00 → Spec-07  
**Oleada:** Oleada 4

---

## Objetivo

Sistema completo de notificaciones push: recordatorios de tareas, avisos de pase de turno, alertas de rescate Premium y resumen diario. Todo gestionado desde backend con FCM.

---

## Reglas de negocio

1. Los recordatorios se calculan y envían desde **backend** (Cloud Functions), nunca desde el cliente.
2. Solo se envía notificación si la tarea **sigue pendiente y asignada al usuario** en el momento del disparo.
3. Cada miembro configura sus preferencias **por hogar** por separado.
4. Un pase de turno genera una notificación **operativa separada** al nuevo responsable.
5. Las tareas completadas, congeladas o reasignadas **no generan recordatorios**.
6. En **Premium**: recordatorios avanzados (antelación configurable, resumen diario, silenciar por tipo).
7. En **Free**: solo aviso al vencer (sin antelación configurable).

---

## Tipos de notificación

| Tipo | Trigger | Destinatario |
|------|---------|-------------|
| `task_due` | Al vencer la tarea | Responsable actual |
| `task_reminder` | X min/h antes de vencer (Premium) | Responsable actual |
| `task_daily_summary` | Hora fija del día (Premium) | Cada miembro |
| `task_passed_to_you` | Pase de turno confirmado | Nuevo responsable |
| `rescue_alert` | Rescate abierto (3 días) | Owner, pagador, miembros |
| `premium_expired` | Premium expirado | Owner, pagador |

---

## Archivos a crear

```
lib/features/notifications/
├── data/
│   └── notification_prefs_repository_impl.dart
├── domain/
│   ├── notification_prefs_repository.dart
│   └── notification_preferences.dart   (modelo freezed por hogar)
├── application/
│   └── notification_prefs_provider.dart
└── presentation/
    └── notification_settings_screen.dart

functions/src/notifications/
├── dispatch_due_reminders.ts     (Job: cada 15 min)
├── send_pass_notification.ts     (llamada desde passTaskTurn)
└── send_rescue_alerts.ts         (llamada desde openRescueWindow)
```

---

## NotificationPreferences (por usuario por hogar)

```dart
@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required String homeId,
    required String uid,
    @Default(true) bool notifyOnDue,
    @Default(false) bool notifyBefore,
    @Default(30) int minutesBefore,       // Premium
    @Default(false) bool dailySummary,    // Premium
    String? dailySummaryTime,             // "08:00" — Premium
    @Default([]) List<String> silencedTypes, // tipos silenciados — Premium
    String? fcmToken,
  }) = _NotificationPreferences;
}
```

Guardadas en: `homes/{homeId}/members/{uid}.notificationPrefs` (campo embebido).

### dispatchDueReminders (Job cron — cada 15 min)

```typescript
// Buscar tareas donde nextDueAt está en la próxima franja de 15 min
// Para cada tarea, verificar que:
//   1. currentAssigneeUid tiene token FCM
//   2. La tarea sigue activa y asignada
//   3. Las prefs del miembro tienen notifyOnDue = true
//   4. No se ha enviado ya esta notificación (deduplicar con un flag temporal)
// Enviar push con: nombre tarea, emoji/icono, nombre del hogar
```

### Pantalla Ajustes de notificaciones

- Por cada hogar del usuario.
- Toggle "Avisar al vencer" (siempre disponible).
- Toggle "Avisar antes" + selector de tiempo (15min, 30min, 1h, 2h) — solo Premium.
- Toggle "Resumen diario" + selector de hora — solo Premium.
- Sección "Silenciar tipos de tarea" — solo Premium.

---

## Tests requeridos

### Unitarios

- `NotificationPreferences` serializa/deserializa correctamente.
- `dispatchDueReminders`: no envía si la tarea ya fue completada.
- `dispatchDueReminders`: no envía si el miembro silenció ese tipo.
- Token FCM nulo → no se intenta enviar.

### De integración (emuladores)

- Crear tarea con `nextDueAt` en 5 min → ejecutar `dispatchDueReminders` → push enviado.
- Completar la tarea antes → ejecutar `dispatchDueReminders` → push NO enviado.

### UI

- Pantalla de notificaciones muestra opciones Premium deshabilitadas en Free.
- Toggle "Avisar antes" en Premium habilita el selector de tiempo.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Recordatorio al vencer:** Crear tarea que vence en 2 minutos → recibir notificación push en el dispositivo.
2. **Sin notificación si completada:** Completar la tarea antes de que venza → no llega la notificación.
3. **Notificación de pase de turno:** Pasar turno → el nuevo responsable recibe push inmediatamente.
4. **Recordatorio con antelación (Premium):** Configurar "Avisar 30 min antes" → crear tarea que vence en 35 min → recibir notificación a los 5 min.
5. **Resumen diario (Premium):** Configurar resumen a las 08:00 → al día siguiente recibir el resumen.
6. **Notificación de rescate:** Simular estado rescue → recibir alerta en el dispositivo.
7. **Ajustes por hogar:** Silenciar notificaciones del Hogar A → recibir del Hogar B → no recibir del Hogar A.

---
---

# Spec-12: Valoraciones, notas privadas y radar de puntos fuertes

**Dependencias previas:** Spec-00 → Spec-09, Spec-10  
**Oleada:** Oleada 5 — Premium only

---

## Objetivo

Implementar el sistema de valoraciones de calidad por tarea completada, notas privadas entre autor y evaluado, y el radar visual de puntos fuertes por miembro y hogar.

---

## Reglas de negocio

1. Valoraciones: **solo Premium**.
2. Solo miembros activos **distintos del ejecutor** pueden valorar una tarea completada.
3. Puntuación: 1-10. Nota textual opcional, máx 300 chars.
4. La nota solo la ven el autor y el evaluado. El resto del hogar solo ve métricas agregadas.
5. Las valoraciones **no alteran el reparto inteligente** por defecto.
6. El radar muestra hasta **10 ejes** (las 10 tareas más frecuentes). El resto en lista textual.
7. El radar es por miembro y por hogar, nunca mezcla entre hogares.

---

## Archivos a crear

```
lib/features/profile/
└── presentation/
    └── widgets/
        ├── radar_chart_widget.dart
        ├── review_dialog.dart
        └── strengths_list_widget.dart

functions/src/tasks/
└── submit_review.ts           (Callable Function)
```

---

## submit_review (Callable Function)

```typescript
export const submitReview = functions.https.onCall(async (data, context) => {
  const { homeId, taskEventId, score, note } = data;
  const reviewerUid = context.auth?.uid;
  
  // 1. Validar que el hogar tiene Premium
  // 2. Leer el evento completed
  // 3. Validar que reviewerUid !== performerUid
  // 4. Validar que reviewerUid es miembro activo del hogar
  // 5. Validar que no existe ya una review de este reviewerUid en este evento
  // 6. Crear review en taskEvents/{eventId}/reviews/{reviewerUid}
  // 7. Actualizar memberTaskStats/{uid_taskId}: avgScore, reviewCount
  // 8. Actualizar members/{performerUid}: avgReviewScore
});
```

### ReviewDialog

```dart
// Aparece al tocar una tarea completada en el historial
// Solo visible si isPremium y currentUid !== performerUid
// Campos: slider 1-10 + campo de nota opcional
// Botón "Enviar valoración"
```

### RadarChartWidget

```dart
// Usa fl_chart o similar para dibujar el radar
// Ejes: una por cada tarea evaluable del miembro en el hogar
// Valor: avgScore / 10 (normalizado 0-1)
// Si > 10 tareas: mostrar las 10 más frecuentes + lista textual de las demás
// El radar por defecto es del miembro viendo su propio perfil
// En perfil ajeno: radar del hogar compartido
```

---

## Tests requeridos

### Unitarios

- `submitReview` rechaza si `score` < 1 o > 10.
- `submitReview` rechaza si `note` > 300 chars.
- `submitReview` rechaza si el usuario ya valoró ese evento.
- `submitReview` rechaza si el usuario es el ejecutor.
- `RadarChartWidget` con 15 tareas → solo muestra 10 en radar, resto en lista.

### De integración

- Crear review → documento en `reviews/{uid}`.
- `avgScore` de `memberTaskStats` recalculado correctamente.
- Segundo review del mismo usuario en el mismo evento → error.

### UI

- Review dialog: slider selecciona 1-10 correctamente.
- Review dialog: nota > 300 chars → truncada o error.
- Radar: 10 ejes visibles con valores correctos.
- En plan Free → dialog de review no aparece.
- Golden tests del radar y del dialog.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Valorar tarea:** En historial, tocar un evento completado por otro miembro → aparece diálogo de valoración → dar 8 y nota "Muy limpio" → confirmar.
2. **Privacidad de nota:** Usuario A valora a B con nota. B ve la nota. C (otro miembro) solo ve el promedio, no la nota.
3. **No puede valorarse a sí mismo:** Tocar un evento propio → no aparece opción de valorar (o está deshabilitada).
4. **Radar con pocas tareas:** Con 3 tareas evaluadas → radar con 3 ejes.
5. **Radar con muchas tareas:** Con 12 tareas evaluadas → radar con 10 ejes + 2 en lista textual.
6. **En plan Free:** Intentar valorar → aparece PremiumFeatureGate.

---
---

# Spec-13: Reparto inteligente y vacaciones/ausencias

**Dependencias previas:** Spec-00 → Spec-10  
**Oleada:** Oleada 4 — Premium only

---

## Objetivo

Implementar el modo `smartDistribution` para asignación inteligente de tareas y el sistema de vacaciones/ausencias que excluye temporalmente a un miembro de la rotación.

---

## Reglas de negocio

1. **Smart Distribution**: solo Premium. Pondera por carga reciente, tiempo desde última ejecución, peso de dificultad y separación mínima antes de repetir.
2. Las **valoraciones de calidad no alteran** el reparto por defecto.
3. Los admins pueden **intervenir manualmente** en una asignación concreta, con registro auditable.
4. Las **ausencias/vacaciones** excluyen a un miembro de la rotación durante un rango de fechas, sin romper el resto de la secuencia.
5. Un miembro en ausencia **no recibe asignaciones ni notificaciones** de tareas.
6. La ausencia tiene fecha de inicio y fin opcionales, o es indefinida hasta que el miembro la desactive.

---

## Archivos a crear

```
lib/features/members/
├── domain/
│   └── vacation.dart              (modelo freezed)
└── presentation/
    └── vacation_screen.dart

lib/core/utils/
└── smart_assignment_calculator.dart

functions/src/tasks/
└── manual_reassign.ts             (Callable — solo admin)
```

---

## SmartAssignmentCalculator

```dart
class SmartAssignmentCalculator {
  static String selectNextAssignee({
    required List<String> order,
    required String currentUid,
    required Map<String, MemberLoadData> loadData,
    required List<String> frozenUids,
    required List<String> absentUids,
  }) {
    final eligible = order
        .where((uid) => !frozenUids.contains(uid) && !absentUids.contains(uid))
        .toList();
    
    if (eligible.isEmpty) return currentUid;
    
    // Calcular score de carga para cada elegible:
    // score = (completions_last_7d * difficultyWeight) 
    //       + (daysSinceLastExecution * -0.1)  // más tiempo sin hacer → más prioritario
    // Menor score = más prioritario para asignación
    
    return eligible.reduce((a, b) => _score(loadData[a]!) < _score(loadData[b]!) ? a : b);
  }
}
```

### Vacation (modelo)

```dart
@freezed
class Vacation with _$Vacation {
  const factory Vacation({
    required String uid,
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
    String? reason,
    required DateTime createdAt,
  }) = _Vacation;
}
```

Guardadas en: `homes/{homeId}/members/{uid}.vacation` (campo embebido o subcolección).

### VacationScreen

- Toggle "Estoy de vacaciones / ausente".
- Selector de fecha inicio y fin (opcionales).
- Campo de motivo opcional.
- Al activar: el miembro se excluye de la rotación.
- La pantalla Hoy muestra un chip "De vacaciones hasta [fecha]".

---

## Tests requeridos

### Unitarios

- `SmartAssignmentCalculator` con 3 miembros: selecciona al menos cargado.
- `SmartAssignmentCalculator` excluye ausentes.
- `SmartAssignmentCalculator` excluye congelados.
- Con todos ausentes/congelados: se asigna al actual.
- Miembro en vacaciones: `isAbsent` devuelve true si la fecha actual está en el rango.

### De integración

- Activar vacaciones → el miembro es excluido de las asignaciones siguientes.
- Fin de vacaciones → el miembro vuelve a la rotación normal.
- Manual reassign por admin → evento auditable creado.

### UI

- VacationScreen muestra toggle y selectores de fecha.
- En la pantalla Hoy, chip de vacaciones visible para el propio miembro.
- En pantalla de miembros, badge de "De vacaciones" visible.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Smart Distribution:** Crear tarea con modo inteligente, 3 miembros con distintas cargas → verificar que se asigna al menos cargado.
2. **Vacaciones simples:** Activar vacaciones → completar varias tareas → confirmar que la persona en vacaciones no es asignada.
3. **Vacaciones con rango de fechas:** Configurar vacaciones de lunes a viernes → el sábado siguiente, el miembro vuelve a la rotación automáticamente.
4. **Reasignación manual:** Como admin, cambiar el responsable de una tarea → evento auditable en historial.
5. **Notificaciones durante vacaciones:** Miembro en vacaciones → no recibe notificaciones de tareas.

---
---

# Spec-14: Ajustes, analítica y observabilidad

**Dependencias previas:** Spec-00 → Spec-13  
**Oleada:** Oleada 5

---

## Objetivo

Pantalla de ajustes completa, instrumentación con Firebase Analytics, Crashlytics, y Remote Config para flags de anuncios y experimentos.

---

## Pantalla de Ajustes

```
Ajustes
├── Cuenta
│   ├── Editar perfil
│   ├── Cambiar contraseña (si email/pass)
│   ├── Gestionar proveedores
│   └── Eliminar cuenta
├── Idioma         ← Abre selector de idioma (consulta Firebase languages)
├── Notificaciones ← Abre notification settings
├── Privacidad
│   └── Teléfono (visible/oculto)
├── Suscripción
│   ├── Ver plan actual
│   ├── Restaurar compras
│   └── Gestionar suscripción
├── Hogar
│   ├── Ajustes del hogar
│   ├── Código de invitación
│   └── Abandonar hogar / Cerrar hogar
└── Acerca de
    ├── Versión de la app
    ├── Términos de uso
    └── Política de privacidad
```

## Eventos de analítica a instrumentar

Ver `CLAUDE.md` para la lista completa. Implementar todos con `FirebaseAnalytics.instance.logEvent(name: ...)`.

Eventos críticos:
- `auth_signup_completed` — al terminar el registro
- `home_created` / `home_joined` — al crear/unirse
- `task_created` / `task_completed` / `task_passed`
- `task_review_submitted`
- `premium_purchase_started` / `premium_purchase_success`
- `premium_rescue_opened` / `premium_downgrade_applied`
- `radar_opened` / `profile_viewed`

## Remote Config

Valores a configurar:
```
ad_banner_enabled: bool (default: true)
ad_banner_unit_android: string
ad_banner_unit_ios: string
paywall_default_plan: "monthly" | "annual"
paywall_show_annual_savings: bool
rescue_notification_days: number (default: 3)
max_review_note_chars: number (default: 300)
```

## Crashlytics

- Configurar `FirebaseCrashlytics.instance.recordError` en todos los catch globales.
- Identificar al usuario con `setUserIdentifier` al autenticarse.
- Log personalizado en operaciones críticas (completar tarea, downgrade).

---

## Tests requeridos

### Unitarios

- Remote Config: valores por defecto correctos si Firebase no responde.
- Analytics: verificar que los eventos se llaman con los parámetros correctos (usando mock).

### UI

- Pantalla de ajustes renderiza todas las secciones.
- Sección "Suscripción" muestra estado correcto (Free/Premium).
- Golden test de la pantalla de ajustes.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Analítica:** Completar el flujo de registro → ir a Firebase Analytics DebugView → ver los eventos `auth_signup_completed`, `home_created`.
2. **Remote Config:** Cambiar `ad_banner_enabled = false` en Remote Config → forzar fetch → el banner desaparece.
3. **Crashlytics:** Forzar un crash (botón de debug) → aparece en Crashlytics Dashboard.
4. **Pantalla de ajustes:** Navegar por todas las secciones → ninguna pantalla da error.
5. **Idioma en ajustes:** Ajustes → Idioma → cambiar a "English" → toda la app cambia al inglés.
6. **Eliminar cuenta:** Ajustes → Cuenta → Eliminar cuenta → confirmar → cuenta borrada de Firebase Auth y datos de Firestore limpiados.
