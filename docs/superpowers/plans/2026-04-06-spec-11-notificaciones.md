# Spec-11: Recordatorios y Notificaciones Push — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el sistema completo de notificaciones push: modelo `NotificationPreferences`, repositorio, provider, pantalla de ajustes, y tres Cloud Functions backend (dispatchDueReminders, sendPassNotification, sendRescueAlerts).

**Architecture:** Las preferencias se guardan como campo embebido `notificationPrefs` en `homes/{homeId}/members/{uid}`. El token FCM se guarda en el mismo campo al inicializar la app. El job `dispatchDueReminders` se ejecuta cada 15 minutos como scheduled function. `sendPassNotification` es llamado internamente desde `passTaskTurn`; `sendRescueAlerts` desde `openRescueWindow`.

**Tech Stack:** Flutter/Dart 3, firebase_messaging (ya en pubspec), freezed, Riverpod, Cloud Functions v2 TypeScript, FCM Admin SDK

---

## Archivos

| Acción | Ruta |
|--------|------|
| Crear | `lib/features/notifications/domain/notification_preferences.dart` |
| Crear | `lib/features/notifications/domain/notification_prefs_repository.dart` |
| Crear | `lib/features/notifications/data/notification_prefs_repository_impl.dart` |
| Crear | `lib/features/notifications/application/notification_prefs_provider.dart` |
| Crear | `lib/features/notifications/application/fcm_token_service.dart` |
| Crear | `lib/features/notifications/presentation/notification_settings_screen.dart` |
| Crear | `functions/src/notifications/dispatch_due_reminders.ts` |
| Crear | `functions/src/notifications/send_pass_notification.ts` |
| Crear | `functions/src/notifications/send_rescue_alerts.ts` |
| Modificar | `functions/src/notifications/index.ts` |
| Modificar | `functions/src/tasks/pass_task_turn.ts` |
| Modificar | `functions/src/entitlement/open_rescue_window.ts` |
| Modificar | `functions/src/jobs/index.ts` |
| Modificar | `lib/core/constants/routes.dart` |
| Modificar | `lib/app.dart` |
| Modificar | `lib/l10n/app_es.arb` + `app_en.arb` + `app_ro.arb` |
| Crear | `test/unit/features/notifications/notification_preferences_test.dart` |
| Crear | `test/unit/features/notifications/dispatch_due_reminders_test.ts` |
| Crear | `test/ui/features/notifications/notification_settings_screen_test.dart` |

---

### Task 1: NotificationPreferences model (freezed)

**Files:**
- Create: `lib/features/notifications/domain/notification_preferences.dart`
- Create: `test/unit/features/notifications/notification_preferences_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/unit/features/notifications/notification_preferences_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('serializa a map correctamente', () {
      const prefs = NotificationPreferences(
        homeId: 'h1',
        uid: 'u1',
        notifyOnDue: true,
        notifyBefore: true,
        minutesBefore: 30,
        dailySummary: false,
      );
      final map = prefs.toMap();
      expect(map['notifyOnDue'], true);
      expect(map['minutesBefore'], 30);
      expect(map['dailySummary'], false);
    });

    test('deserializa desde map con valores por defecto', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {});
      expect(prefs.notifyOnDue, true);
      expect(prefs.notifyBefore, false);
      expect(prefs.minutesBefore, 30);
      expect(prefs.dailySummary, false);
    });

    test('token FCM nulo en fromMap si no está en el mapa', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {});
      expect(prefs.fcmToken, isNull);
    });

    test('silencedTypes deserializa lista correctamente', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {
        'silencedTypes': ['task_due', 'task_reminder'],
      });
      expect(prefs.silencedTypes, contains('task_due'));
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/features/notifications/notification_preferences_test.dart
```
Resultado esperado: `Error: 'NotificationPreferences' not found`

- [ ] **Step 3: Crear el modelo**

Crear directorio: `lib/features/notifications/domain/`

```dart
// lib/features/notifications/domain/notification_preferences.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required String homeId,
    required String uid,
    @Default(true) bool notifyOnDue,
    @Default(false) bool notifyBefore,
    @Default(30) int minutesBefore,
    @Default(false) bool dailySummary,
    String? dailySummaryTime,
    @Default([]) List<String> silencedTypes,
    String? fcmToken,
  }) = _NotificationPreferences;

  const NotificationPreferences._();

  factory NotificationPreferences.fromMap(
    String homeId,
    String uid,
    Map<String, dynamic> map,
  ) {
    return NotificationPreferences(
      homeId: homeId,
      uid: uid,
      notifyOnDue: map['notifyOnDue'] as bool? ?? true,
      notifyBefore: map['notifyBefore'] as bool? ?? false,
      minutesBefore: map['minutesBefore'] as int? ?? 30,
      dailySummary: map['dailySummary'] as bool? ?? false,
      dailySummaryTime: map['dailySummaryTime'] as String?,
      silencedTypes: (map['silencedTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'notifyOnDue': notifyOnDue,
    'notifyBefore': notifyBefore,
    'minutesBefore': minutesBefore,
    'dailySummary': dailySummary,
    'dailySummaryTime': dailySummaryTime,
    'silencedTypes': silencedTypes,
    'fcmToken': fcmToken,
  };
}
```

- [ ] **Step 4: Generar código freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Confirmar que los tests pasan**

```bash
flutter test test/unit/features/notifications/notification_preferences_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 6: Commit**

```bash
git add lib/features/notifications/ test/unit/features/notifications/notification_preferences_test.dart
git commit -m "feat(notifications): add NotificationPreferences model with serialization"
```

---

### Task 2: NotificationPrefsRepository (interfaz + impl)

**Files:**
- Create: `lib/features/notifications/domain/notification_prefs_repository.dart`
- Create: `lib/features/notifications/data/notification_prefs_repository_impl.dart`

- [ ] **Step 1: Crear la interfaz**

```dart
// lib/features/notifications/domain/notification_prefs_repository.dart
import 'notification_preferences.dart';

abstract interface class NotificationPrefsRepository {
  /// Stream de las preferencias del usuario en un hogar concreto.
  Stream<NotificationPreferences> watchPrefs(String homeId, String uid);

  /// Guarda (o actualiza) las preferencias.
  Future<void> savePrefs(NotificationPreferences prefs);

  /// Actualiza solo el token FCM.
  Future<void> updateFcmToken(String homeId, String uid, String token);
}
```

- [ ] **Step 2: Crear la implementación**

Crear directorio: `lib/features/notifications/data/`

```dart
// lib/features/notifications/data/notification_prefs_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_prefs_repository.dart';

class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  NotificationPrefsRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _memberRef(String homeId, String uid) =>
      _firestore.collection('homes').doc(homeId).collection('members').doc(uid);

  @override
  Stream<NotificationPreferences> watchPrefs(String homeId, String uid) {
    return _memberRef(homeId, uid).snapshots().map((snap) {
      if (!snap.exists) {
        return NotificationPreferences(homeId: homeId, uid: uid);
      }
      final data = snap.data()!;
      final prefsMap = (data['notificationPrefs'] as Map<String, dynamic>?) ?? {};
      return NotificationPreferences.fromMap(homeId, uid, prefsMap);
    });
  }

  @override
  Future<void> savePrefs(NotificationPreferences prefs) async {
    await _memberRef(prefs.homeId, prefs.uid).update({
      'notificationPrefs': prefs.toMap(),
    });
  }

  @override
  Future<void> updateFcmToken(String homeId, String uid, String token) async {
    await _memberRef(homeId, uid).set(
      {'notificationPrefs': {'fcmToken': token}},
      SetOptions(merge: true),
    );
  }
}
```

- [ ] **Step 3: Verificar análisis**

```bash
flutter analyze lib/features/notifications/
```
Resultado esperado: sin errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/notifications/domain/notification_prefs_repository.dart lib/features/notifications/data/notification_prefs_repository_impl.dart
git commit -m "feat(notifications): add NotificationPrefsRepository interface and Firestore impl"
```

---

### Task 3: NotificationPrefsProvider + FCM token service

**Files:**
- Create: `lib/features/notifications/application/notification_prefs_provider.dart`
- Create: `lib/features/notifications/application/fcm_token_service.dart`

- [ ] **Step 1: Crear el provider**

Crear directorio: `lib/features/notifications/application/`

```dart
// lib/features/notifications/application/notification_prefs_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notification_prefs_repository_impl.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_prefs_repository.dart';

part 'notification_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationPrefsRepository notificationPrefsRepository(NotificationPrefsRepositoryRef ref) {
  return NotificationPrefsRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<NotificationPreferences> notificationPrefs(
  NotificationPrefsRef ref, {
  required String homeId,
  required String uid,
}) {
  return ref.watch(notificationPrefsRepositoryProvider).watchPrefs(homeId, uid);
}

@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save(NotificationPreferences prefs) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationPrefsRepositoryProvider).savePrefs(prefs),
    );
  }
}
```

- [ ] **Step 2: Crear el servicio FCM token**

```dart
// lib/features/notifications/application/fcm_token_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_prefs_repository.dart';

/// Obtiene el token FCM actual y lo guarda en Firestore.
/// Llamar una vez al autenticarse y al recibir un refresh de token.
class FcmTokenService {
  FcmTokenService({
    required NotificationPrefsRepository repository,
    required FirebaseMessaging messaging,
  })  : _repository = repository,
        _messaging = messaging;

  final NotificationPrefsRepository _repository;
  final FirebaseMessaging _messaging;

  Future<void> initAndSaveToken(String homeId, String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _repository.updateFcmToken(homeId, uid, token);
  }

  void listenForTokenRefresh(String homeId, String uid) {
    _messaging.onTokenRefresh.listen((token) {
      _repository.updateFcmToken(homeId, uid, token);
    });
  }
}
```

- [ ] **Step 3: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/notifications/application/
git commit -m "feat(notifications): add NotificationPrefsProvider and FcmTokenService"
```

---

### Task 4: Strings ARB + Rutas

**Files:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`
- Modify: `lib/core/constants/routes.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Añadir claves ARB en app_es.arb**

```json
  "notification_settings_title": "Notificaciones",
  "@notification_settings_title": { "description": "Notification settings screen title" },
  "notification_on_due_label": "Avisar al vencer",
  "@notification_on_due_label": { "description": "Notify on due toggle" },
  "notification_before_label": "Avisar antes de vencer",
  "@notification_before_label": { "description": "Notify before due toggle" },
  "notification_minutes_before_label": "Tiempo de antelación",
  "@notification_minutes_before_label": { "description": "Minutes before label" },
  "notification_daily_summary_label": "Resumen diario",
  "@notification_daily_summary_label": { "description": "Daily summary toggle" },
  "notification_summary_time_label": "Hora del resumen",
  "@notification_summary_time_label": { "description": "Daily summary time label" },
  "notification_silenced_types_label": "Silenciar tipos de tarea",
  "@notification_silenced_types_label": { "description": "Silenced types section label" },
  "notification_premium_only": "Solo Premium",
  "@notification_premium_only": { "description": "Premium-only badge" },
  "notification_15min": "15 minutos",
  "@notification_15min": { "description": "15 minutes option" },
  "notification_30min": "30 minutos",
  "@notification_30min": { "description": "30 minutes option" },
  "notification_1h": "1 hora",
  "@notification_1h": { "description": "1 hour option" },
  "notification_2h": "2 horas",
  "@notification_2h": { "description": "2 hours option" }
```

- [ ] **Step 2: Añadir las mismas claves en app_en.arb**

```json
  "notification_settings_title": "Notifications",
  "@notification_settings_title": { "description": "Notification settings screen title" },
  "notification_on_due_label": "Notify when due",
  "@notification_on_due_label": { "description": "Notify on due toggle" },
  "notification_before_label": "Notify before due",
  "@notification_before_label": { "description": "Notify before due toggle" },
  "notification_minutes_before_label": "Lead time",
  "@notification_minutes_before_label": { "description": "Minutes before label" },
  "notification_daily_summary_label": "Daily summary",
  "@notification_daily_summary_label": { "description": "Daily summary toggle" },
  "notification_summary_time_label": "Summary time",
  "@notification_summary_time_label": { "description": "Daily summary time label" },
  "notification_silenced_types_label": "Silence task types",
  "@notification_silenced_types_label": { "description": "Silenced types section label" },
  "notification_premium_only": "Premium only",
  "@notification_premium_only": { "description": "Premium-only badge" },
  "notification_15min": "15 minutes",
  "@notification_15min": { "description": "15 minutes option" },
  "notification_30min": "30 minutes",
  "@notification_30min": { "description": "30 minutes option" },
  "notification_1h": "1 hour",
  "@notification_1h": { "description": "1 hour option" },
  "notification_2h": "2 hours",
  "@notification_2h": { "description": "2 hours option" }
```

- [ ] **Step 3: Añadir las mismas claves en app_ro.arb**

```json
  "notification_settings_title": "Notificări",
  "@notification_settings_title": { "description": "Notification settings screen title" },
  "notification_on_due_label": "Notifică la scadență",
  "@notification_on_due_label": { "description": "Notify on due toggle" },
  "notification_before_label": "Notifică înainte de scadență",
  "@notification_before_label": { "description": "Notify before due toggle" },
  "notification_minutes_before_label": "Timp de avans",
  "@notification_minutes_before_label": { "description": "Minutes before label" },
  "notification_daily_summary_label": "Rezumat zilnic",
  "@notification_daily_summary_label": { "description": "Daily summary toggle" },
  "notification_summary_time_label": "Ora rezumatului",
  "@notification_summary_time_label": { "description": "Daily summary time label" },
  "notification_silenced_types_label": "Silențiează tipuri de sarcini",
  "@notification_silenced_types_label": { "description": "Silenced types section label" },
  "notification_premium_only": "Doar Premium",
  "@notification_premium_only": { "description": "Premium-only badge" },
  "notification_15min": "15 minute",
  "@notification_15min": { "description": "15 minutes option" },
  "notification_30min": "30 de minute",
  "@notification_30min": { "description": "30 minutes option" },
  "notification_1h": "1 oră",
  "@notification_1h": { "description": "1 hour option" },
  "notification_2h": "2 ore",
  "@notification_2h": { "description": "2 hours option" }
```

- [ ] **Step 4: Añadir ruta en routes.dart**

```dart
  static const String notificationSettings = '/notification-settings';
```
Y añadir `notificationSettings` a la lista `all`.

- [ ] **Step 5: Registrar ruta en app.dart**

```dart
import 'features/notifications/presentation/notification_settings_screen.dart';

// Añadir dentro del router:
GoRoute(
  path: AppRoutes.notificationSettings,
  builder: (_, __) => const NotificationSettingsScreen(),
),
```

- [ ] **Step 6: Regenerar**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/ lib/core/constants/routes.dart lib/app.dart
git commit -m "feat(notifications): add notification ARB strings and route"
```

---

### Task 5: NotificationSettingsScreen

**Files:**
- Create: `lib/features/notifications/presentation/notification_settings_screen.dart`
- Create: `test/ui/features/notifications/notification_settings_screen_test.dart`

- [ ] **Step 1: Escribir test UI fallido**

```dart
// test/ui/features/notifications/notification_settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/application/notification_prefs_provider.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';
import 'package:toka/features/notifications/presentation/notification_settings_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

const _prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');

Widget _wrap(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: [
        notificationPrefsProvider(homeId: 'h1', uid: 'u1')
            .overrideWith((_) => Stream.value(_prefs)),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('Pantalla muestra toggle "Avisar al vencer" habilitado por defecto', (t) async {
    await t.pumpWidget(_wrap(const NotificationSettingsScreen(homeId: 'h1', uid: 'u1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('toggle_on_due')), findsOneWidget);
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('toggle_on_due')));
    expect(sw.value, true);
  });

  testWidgets('Opciones Premium están deshabilitadas en plan Free', (t) async {
    await t.pumpWidget(_wrap(const NotificationSettingsScreen(homeId: 'h1', uid: 'u1')));
    await t.pumpAndSettle();
    // El toggle "Avisar antes" debe estar deshabilitado (null onChanged)
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('toggle_notify_before')));
    expect(sw.onChanged, isNull);
  });
}
```

- [ ] **Step 2: Confirmar que el test falla**

```bash
flutter test test/ui/features/notifications/notification_settings_screen_test.dart
```
Resultado esperado: `Error: 'NotificationSettingsScreen' not found`

- [ ] **Step 3: Crear NotificationSettingsScreen**

Crear directorio: `lib/features/notifications/presentation/`

```dart
// lib/features/notifications/presentation/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/notification_prefs_provider.dart';
import '../domain/notification_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _prefs;

  bool _isPremium(WidgetRef ref) {
    final sub = ref.watch(subscriptionStateProvider);
    return sub.when(
      free: () => false,
      active: (_, __, ___) => true,
      cancelledPendingEnd: (_, __) => true,
      rescue: (_, __, ___) => true,
      expiredFree: () => false,
      restorable: (_) => false,
      purged: () => false,
    );
  }

  Future<void> _save(NotificationPreferences prefs) async {
    await ref.read(notificationPrefsNotifierProvider.notifier).save(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPremium = _isPremium(ref);

    final prefsAsync = ref.watch(
      notificationPrefsProvider(homeId: widget.homeId, uid: widget.uid),
    );

    prefsAsync.whenData((p) {
      if (!mounted) return;
      if (_prefs == null) setState(() => _prefs = p);
    });

    final prefs = _prefs ?? const NotificationPreferences(homeId: '', uid: '');

    final minutesOptions = {
      15: l10n.notification_15min,
      30: l10n.notification_30min,
      60: l10n.notification_1h,
      120: l10n.notification_2h,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notification_settings_title)),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => ListView(
          children: [
            SwitchListTile(
              key: const Key('toggle_on_due'),
              title: Text(l10n.notification_on_due_label),
              value: prefs.notifyOnDue,
              onChanged: (v) {
                final updated = prefs.copyWith(notifyOnDue: v);
                setState(() => _prefs = updated);
                _save(updated);
              },
            ),
            const Divider(),
            SwitchListTile(
              key: const Key('toggle_notify_before'),
              title: Text(l10n.notification_before_label),
              subtitle: !isPremium
                  ? Text(l10n.notification_premium_only,
                      style: const TextStyle(color: Colors.orange))
                  : null,
              value: prefs.notifyBefore,
              onChanged: isPremium
                  ? (v) {
                      final updated = prefs.copyWith(notifyBefore: v);
                      setState(() => _prefs = updated);
                      _save(updated);
                    }
                  : null,
            ),
            if (prefs.notifyBefore && isPremium)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  value: minutesOptions.containsKey(prefs.minutesBefore)
                      ? prefs.minutesBefore
                      : 30,
                  decoration: InputDecoration(
                      labelText: l10n.notification_minutes_before_label),
                  items: minutesOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final updated = prefs.copyWith(minutesBefore: v);
                    setState(() => _prefs = updated);
                    _save(updated);
                  },
                ),
              ),
            const Divider(),
            SwitchListTile(
              key: const Key('toggle_daily_summary'),
              title: Text(l10n.notification_daily_summary_label),
              subtitle: !isPremium
                  ? Text(l10n.notification_premium_only,
                      style: const TextStyle(color: Colors.orange))
                  : null,
              value: prefs.dailySummary,
              onChanged: isPremium
                  ? (v) {
                      final updated = prefs.copyWith(dailySummary: v);
                      setState(() => _prefs = updated);
                      _save(updated);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/ui/features/notifications/notification_settings_screen_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/features/notifications/presentation/ test/ui/features/notifications/
git commit -m "feat(notifications): add NotificationSettingsScreen with premium gates"
```

---

### Task 6: dispatchDueReminders Cloud Function

**Files:**
- Create: `functions/src/notifications/dispatch_due_reminders.ts`

- [ ] **Step 1: Crear la función**

```typescript
// functions/src/notifications/dispatch_due_reminders.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Job cada 15 minutos.
 * Busca tareas activas cuyo nextDueAt cae en los próximos 15 minutos
 * y envía notificaciones push a los responsables que tengan token FCM
 * y hayan activado notifyOnDue.
 */
export const dispatchDueReminders = onSchedule("*/15 * * * *", async () => {
  const now = new Date();
  const in15 = new Date(now.getTime() + 15 * 60 * 1000);

  // Buscar todas las tareas activas que vencen en la próxima franja
  const homesSnap = await db.collection("homes").get();
  let sent = 0;

  for (const homeDoc of homesSnap.docs) {
    const homeId = homeDoc.id;

    const tasksSnap = await db
      .collection("homes").doc(homeId).collection("tasks")
      .where("status", "==", "active")
      .where("nextDueAt", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("nextDueAt", "<=", admin.firestore.Timestamp.fromDate(in15))
      .get();

    for (const taskDoc of tasksSnap.docs) {
      const task = taskDoc.data();
      const assigneeUid: string | null = task["currentAssigneeUid"] ?? null;
      if (!assigneeUid) continue;

      // Leer preferencias del miembro
      const memberRef = db.collection("homes").doc(homeId).collection("members").doc(assigneeUid);
      const memberSnap = await memberRef.get();
      if (!memberSnap.exists) continue;

      const memberData = memberSnap.data()!;
      const notifPrefs = memberData["notificationPrefs"] as Record<string, unknown> | undefined;
      const fcmToken = notifPrefs?.["fcmToken"] as string | undefined;
      const notifyOnDue = (notifPrefs?.["notifyOnDue"] as boolean | undefined) ?? true;

      if (!fcmToken || !notifyOnDue) continue;

      // Verificar deduplicación
      const notifKey = `${taskDoc.id}_${now.toISOString().slice(0, 13)}`; // dedup por hora
      const sentRef = db.collection("homes").doc(homeId)
        .collection("sentNotifications").doc(notifKey);
      const sentSnap = await sentRef.get();
      if (sentSnap.exists) continue;

      const homeName: string = homeDoc.data()["name"] ?? "Hogar";
      const taskTitle: string = task["title"] ?? "Tarea";

      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: `⏰ ${taskTitle}`,
            body: `Tu turno en ${homeName} vence pronto.`,
          },
          data: {
            type: "task_due",
            homeId,
            taskId: taskDoc.id,
          },
        });
        // Marcar como enviado
        await sentRef.set({ sentAt: admin.firestore.FieldValue.serverTimestamp() });
        sent++;
      } catch (err) {
        logger.warn(`FCM send failed for token ${fcmToken}:`, err);
      }
    }
  }

  logger.info(`dispatchDueReminders: sent ${sent} notifications`);
});
```

- [ ] **Step 2: Compilar**

```bash
cd functions && npm run build
```
Resultado esperado: sin errores.

- [ ] **Step 3: Commit**

```bash
git add functions/src/notifications/dispatch_due_reminders.ts
git commit -m "feat(notifications): add dispatchDueReminders scheduled job (every 15min)"
```

---

### Task 7: sendPassNotification + sendRescueAlerts

**Files:**
- Create: `functions/src/notifications/send_pass_notification.ts`
- Create: `functions/src/notifications/send_rescue_alerts.ts`
- Modify: `functions/src/tasks/pass_task_turn.ts`
- Modify: `functions/src/entitlement/open_rescue_window.ts`

- [ ] **Step 1: Crear sendPassNotification**

```typescript
// functions/src/notifications/send_pass_notification.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Envía notificación push al nuevo responsable cuando se le pasa el turno.
 * Llamado internamente desde passTaskTurn (no es una Callable Function pública).
 */
export async function sendPassNotification(
  homeId: string,
  taskId: string,
  taskTitle: string,
  toUid: string,
  fromUid: string
): Promise<void> {
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(toUid);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) return;

  const memberData = memberSnap.data()!;
  const notifPrefs = memberData["notificationPrefs"] as Record<string, unknown> | undefined;
  const fcmToken = notifPrefs?.["fcmToken"] as string | undefined;
  if (!fcmToken) return;

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";

  try {
    await messaging.send({
      token: fcmToken,
      notification: {
        title: `🔁 Turno recibido: ${taskTitle}`,
        body: `Ahora es tu turno en ${homeName}.`,
      },
      data: {
        type: "task_passed_to_you",
        homeId,
        taskId,
        fromUid,
      },
    });
    logger.info(`sendPassNotification: sent to ${toUid} for task ${taskId}`);
  } catch (err) {
    logger.warn(`sendPassNotification failed for token ${fcmToken}:`, err);
  }
}
```

- [ ] **Step 2: Crear sendRescueAlerts**

```typescript
// functions/src/notifications/send_rescue_alerts.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Envía notificaciones de alerta de rescate al owner, pagador y miembros del hogar.
 * Llamado desde openRescueWindow.
 */
export async function sendRescueAlerts(homeId: string, daysLeft: number): Promise<void> {
  const membersSnap = await db
    .collection("homes").doc(homeId).collection("members")
    .where("status", "==", "active")
    .get();

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";

  const tokens: string[] = [];
  for (const mDoc of membersSnap.docs) {
    const mData = mDoc.data();
    const notifPrefs = mData["notificationPrefs"] as Record<string, unknown> | undefined;
    const token = notifPrefs?.["fcmToken"] as string | undefined;
    if (token) tokens.push(token);
  }

  if (!tokens.length) return;

  const results = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: `🚨 ${homeName}: Rescate Premium`,
      body: `Tu suscripción vence en ${daysLeft} días. Renueva para conservar tus datos.`,
    },
    data: {
      type: "rescue_alert",
      homeId,
      daysLeft: String(daysLeft),
    },
  });

  logger.info(`sendRescueAlerts: sent to ${results.successCount}/${tokens.length} members of ${homeId}`);
}
```

- [ ] **Step 3: Actualizar pass_task_turn.ts para llamar sendPassNotification**

Añadir al final del archivo `functions/src/tasks/pass_task_turn.ts` (después del `return result;` y antes del último `}`):

```typescript
// Añadir import al inicio:
import { sendPassNotification } from "../notifications/send_pass_notification";

// Reemplazar el bloque post-transacción (después del return result):
  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Failed to update dashboard after pass", err)
  );

  // Notificar al nuevo responsable (si hay candidato)
  if (!result.noCandidate) {
    sendPassNotification(homeId, taskId, '', result.toUid, uid).catch((err) =>
      logger.warn("sendPassNotification failed", err)
    );
  }

  return result;
```

**Nota:** Para incluir el título de la tarea en la notificación, es necesario leer el dato `taskTitleSnapshot` del evento. Simplificar: leer el título antes de la transacción.

El archivo `pass_task_turn.ts` completo modificado queda así (añadir el import arriba y el call de notificación):

```typescript
// functions/src/tasks/pass_task_turn.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";
import { sendPassNotification } from "../notifications/send_pass_notification";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function getNextEligibleMember(
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

export const passTaskTurn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, reason } = request.data as {
    homeId: string;
    taskId: string;
    reason?: string;
  };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  // Leer título antes de la transacción para la notificación
  const taskSnap = await db.collection("homes").doc(homeId).collection("tasks").doc(taskId).get();
  const taskTitle: string = taskSnap.data()?.["title"] ?? "";

  const result = await db.runTransaction(async (tx) => {
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnapTx = await tx.get(taskRef);
    if (!taskSnapTx.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnapTx.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    const membersSnap = await tx.get(
      db.collection("homes").doc(homeId).collection("members")
    );
    const frozenUids: string[] = [];
    for (const mDoc of membersSnap.docs) {
      const mData = mDoc.data();
      if (mData["status"] === "frozen" || mData["status"] === "absent") {
        frozenUids.push(mDoc.id);
      }
    }

    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const toUid = getNextEligibleMember(assignmentOrder, uid, frozenUids);
    const noCandidate = toUid === uid;

    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const completed: number = (member["completedCount"] as number) ?? 0;
    const passed: number = (member["passedCount"] as number) ?? 0;
    const complianceBefore = completed / Math.max(completed + passed, 1);
    const complianceAfter = completed / Math.max(completed + passed + 1, 1);

    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "passed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      toUid,
      reason: reason ?? null,
      noCandidate,
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: true,
    });

    tx.update(taskRef, {
      currentAssigneeUid: toUid,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(memberRef, {
      passedCount: FieldValue.increment(1),
      complianceRate: complianceAfter,
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return { toUid, noCandidate, complianceBefore, complianceAfter };
  });

  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Failed to update dashboard after pass", err)
  );

  if (!result.noCandidate) {
    sendPassNotification(homeId, taskId, taskTitle, result.toUid, uid).catch((err) =>
      logger.warn("sendPassNotification failed", err)
    );
  }

  return result;
});
```

- [ ] **Step 4: Actualizar open_rescue_window.ts para llamar sendRescueAlerts**

Añadir al inicio de `functions/src/entitlement/open_rescue_window.ts`:
```typescript
import { sendRescueAlerts } from "../notifications/send_rescue_alerts";
```

Añadir dentro del bucle `for (const doc of snapshot.docs)`, después de `batch.set(dashRef, ...)`:
```typescript
    // Enviar alertas a miembros (fuera del batch, es async independiente)
    sendRescueAlerts(doc.id, daysLeft).catch((err) =>
      logger.warn(`sendRescueAlerts failed for home ${doc.id}:`, err)
    );
```

- [ ] **Step 5: Actualizar functions/src/notifications/index.ts**

```typescript
// functions/src/notifications/index.ts
export { dispatchDueReminders } from "./dispatch_due_reminders";
// send_pass_notification y send_rescue_alerts son helpers internos, no se exportan como CF
```

- [ ] **Step 6: Compilar**

```bash
cd functions && npm run build
```
Resultado esperado: sin errores.

- [ ] **Step 8: Commit**

```bash
git add functions/src/notifications/ functions/src/tasks/pass_task_turn.ts functions/src/entitlement/open_rescue_window.ts
git commit -m "feat(notifications): add sendPassNotification, sendRescueAlerts, wire into existing functions"
```

---

### Task 8: Ejecutar suite completa

- [ ] **Step 1: Ejecutar tests Flutter**

```bash
flutter test test/unit/ test/integration/ test/ui/
```
Resultado esperado: todos pasan.

- [ ] **Step 2: Compilar Functions**

```bash
cd functions && npm run build
```

- [ ] **Step 3: Análisis estático**

```bash
flutter analyze
```

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "feat(spec-11): complete notifications push implementation"
```

---

## Pruebas manuales requeridas (Spec-11)

1. **Recordatorio al vencer:** Crear tarea que vence en 2 minutos con `notifyOnDue = true` y token FCM guardado → recibir notificación push.
2. **Sin notificación si completada:** Completar la tarea antes de que venza → no llega la notificación (el job no la encuentra activa).
3. **Notificación de pase de turno:** Pasar turno a otro miembro → ese miembro recibe push inmediatamente.
4. **Recordatorio con antelación (Premium):** Configurar "Avisar 30 min antes" en ajustes → crear tarea que vence en 35 min → recibir notificación a los 5 min (cuando el job corre).
5. **Ajustes por hogar:** Desactivar `notifyOnDue` → ya no llegan notificaciones de ese hogar.
6. **Opciones Premium deshabilitadas:** En plan Free, los toggles de "Avisar antes" y "Resumen diario" aparecen deshabilitados.
