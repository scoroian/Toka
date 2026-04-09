# Spec-14: Ajustes, Analítica y Observabilidad — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar la pantalla de Ajustes completa con todas sus secciones, extender `AnalyticsService` con los eventos críticos de la app, crear `RemoteConfigService` y `CrashlyticsService`, e inicializar todo en `main_prod.dart`.

**Architecture:** `AnalyticsService` ya existe en `lib/shared/services/`. Se extenderá con métodos tipados para cada evento crítico. `RemoteConfigService` y `CrashlyticsService` son nuevos singletons. La pantalla `SettingsScreen` es una pantalla de navegación (ListTile groups), accesible desde la ruta existente `/settings`. La inicialización ocurre en `main_prod.dart` y `main_dev.dart`.

**Tech Stack:** Flutter/Dart 3, firebase_analytics (ya en pubspec), firebase_crashlytics, firebase_remote_config, Riverpod, go_router

---

## Archivos

| Acción | Ruta |
|--------|------|
| Modificar | `lib/shared/services/analytics_service.dart` |
| Crear | `lib/shared/services/remote_config_service.dart` |
| Crear | `lib/shared/services/crashlytics_service.dart` |
| Crear | `lib/features/settings/presentation/settings_screen.dart` |
| Modificar | `lib/main_prod.dart` |
| Modificar | `lib/main_dev.dart` |
| Modificar | `lib/app.dart` (añadir ruta settings) |
| Modificar | `lib/l10n/app_es.arb` + `app_en.arb` + `app_ro.arb` |
| Crear | `test/unit/shared/services/remote_config_service_test.dart` |
| Crear | `test/unit/shared/services/crashlytics_service_test.dart` |
| Crear | `test/ui/features/settings/settings_screen_test.dart` |
| Crear | `test/ui/features/settings/goldens/settings_screen.png` |

---

### Task 1: Extender AnalyticsService con eventos críticos

**Files:**
- Modify: `lib/shared/services/analytics_service.dart`
- Modify: `test/unit/shared/services/analytics_service_test.dart`

- [ ] **Step 1: Añadir tests para los nuevos métodos**

Añadir al final de `test/unit/shared/services/analytics_service_test.dart` (dentro del `main()`):

```dart
  group('AnalyticsService event methods', () {
    test('logTaskCompleted llama logEvent con task_completed', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await service.logTaskCompleted(homeId: 'h1', taskId: 't1');

      verify(() => mockAnalytics.logEvent(
            name: 'task_completed',
            parameters: any(named: 'parameters'),
          )).called(1);
    });

    test('logPremiumPurchaseStarted llama logEvent con premium_purchase_started', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      await service.logPremiumPurchaseStarted(plan: 'monthly');

      verify(() => mockAnalytics.logEvent(
            name: 'premium_purchase_started',
            parameters: any(named: 'parameters'),
          )).called(1);
    });
  });
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/shared/services/analytics_service_test.dart
```
Resultado esperado: `Error: 'logTaskCompleted' not found`

- [ ] **Step 3: Extender AnalyticsService**

Reemplazar el contenido de `lib/shared/services/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../core/utils/logger.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  // ─── Métodos base ─────────────────────────────────────────────────────────

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, st) {
      AppLogger.error('Analytics logEvent failed: $name', e, st);
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e, st) {
      AppLogger.error('Analytics setUserId failed', e, st);
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, st) {
      AppLogger.error('Analytics logScreenView failed', e, st);
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> logSignupCompleted({required String method}) =>
      logEvent('auth_signup_completed', parameters: {'method': method});

  // ─── Homes ────────────────────────────────────────────────────────────────

  Future<void> logHomeCreated({required String homeId}) =>
      logEvent('home_created', parameters: {'home_id': homeId});

  Future<void> logHomeJoined({required String homeId}) =>
      logEvent('home_joined', parameters: {'home_id': homeId});

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<void> logTaskCreated({required String homeId, required String taskId}) =>
      logEvent('task_created', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  Future<void> logTaskCompleted({required String homeId, required String taskId}) =>
      logEvent('task_completed', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  Future<void> logTaskPassed({required String homeId, required String taskId}) =>
      logEvent('task_passed', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  // ─── Reviews ──────────────────────────────────────────────────────────────

  Future<void> logTaskReviewSubmitted({
    required String homeId,
    required String taskEventId,
    required int score,
  }) =>
      logEvent('task_review_submitted', parameters: {
        'home_id': homeId,
        'task_event_id': taskEventId,
        'score': score,
      });

  // ─── Premium ──────────────────────────────────────────────────────────────

  Future<void> logPremiumPurchaseStarted({required String plan}) =>
      logEvent('premium_purchase_started', parameters: {'plan': plan});

  Future<void> logPremiumPurchaseSuccess({required String plan}) =>
      logEvent('premium_purchase_success', parameters: {'plan': plan});

  Future<void> logPremiumRescueOpened({required String homeId}) =>
      logEvent('premium_rescue_opened', parameters: {'home_id': homeId});

  Future<void> logPremiumDowngradeApplied({required String homeId}) =>
      logEvent('premium_downgrade_applied', parameters: {'home_id': homeId});

  // ─── Perfil / Radar ───────────────────────────────────────────────────────

  Future<void> logRadarOpened({required String homeId}) =>
      logEvent('radar_opened', parameters: {'home_id': homeId});

  Future<void> logProfileViewed({required String viewedUid}) =>
      logEvent('profile_viewed', parameters: {'viewed_uid': viewedUid});
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/unit/shared/services/analytics_service_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/shared/services/analytics_service.dart test/unit/shared/services/analytics_service_test.dart
git commit -m "feat(analytics): extend AnalyticsService with typed event methods"
```

---

### Task 2: RemoteConfigService

**Files:**
- Create: `lib/shared/services/remote_config_service.dart`
- Create: `test/unit/shared/services/remote_config_service_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/unit/shared/services/remote_config_service_test.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/remote_config_service.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late RemoteConfigService service;

  setUp(() {
    mockRemoteConfig = MockFirebaseRemoteConfig();
    service = RemoteConfigService(mockRemoteConfig);
  });

  group('RemoteConfigService defaults', () {
    test('adBannerEnabled devuelve true por defecto si Firebase no responde', () {
      when(() => mockRemoteConfig.getBool('ad_banner_enabled')).thenThrow(Exception('no internet'));
      expect(service.adBannerEnabled, true);
    });

    test('rescueNotificationDays devuelve 3 por defecto', () {
      when(() => mockRemoteConfig.getInt('rescue_notification_days')).thenThrow(Exception());
      expect(service.rescueNotificationDays, 3);
    });

    test('maxReviewNoteChars devuelve 300 por defecto', () {
      when(() => mockRemoteConfig.getInt('max_review_note_chars')).thenThrow(Exception());
      expect(service.maxReviewNoteChars, 300);
    });

    test('paywallDefaultPlan devuelve "monthly" por defecto', () {
      when(() => mockRemoteConfig.getString('paywall_default_plan')).thenThrow(Exception());
      expect(service.paywallDefaultPlan, 'monthly');
    });

    test('adBannerEnabled delega a Firebase cuando funciona', () {
      when(() => mockRemoteConfig.getBool('ad_banner_enabled')).thenReturn(false);
      expect(service.adBannerEnabled, false);
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/shared/services/remote_config_service_test.dart
```
Resultado esperado: `Error: 'RemoteConfigService' not found`

- [ ] **Step 3: Crear RemoteConfigService**

```dart
// lib/shared/services/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/utils/logger.dart';

/// Acceso tipado a Firebase Remote Config.
/// Los valores por defecto se usan cuando Firebase no está disponible.
class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  static const _defaults = {
    'ad_banner_enabled': true,
    'ad_banner_unit_android': '',
    'ad_banner_unit_ios': '',
    'paywall_default_plan': 'monthly',
    'paywall_show_annual_savings': true,
    'rescue_notification_days': 3,
    'max_review_note_chars': 300,
  };

  Future<void> init() async {
    try {
      await _remoteConfig.setDefaults(_defaults.map(
        (k, v) => MapEntry(k, v),
      ));
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e, st) {
      AppLogger.error('RemoteConfig init failed — using defaults', e, st);
    }
  }

  bool get adBannerEnabled {
    try {
      return _remoteConfig.getBool('ad_banner_enabled');
    } catch (_) {
      return true;
    }
  }

  String get adBannerUnitAndroid {
    try {
      return _remoteConfig.getString('ad_banner_unit_android');
    } catch (_) {
      return '';
    }
  }

  String get adBannerUnitIos {
    try {
      return _remoteConfig.getString('ad_banner_unit_ios');
    } catch (_) {
      return '';
    }
  }

  String get paywallDefaultPlan {
    try {
      return _remoteConfig.getString('paywall_default_plan');
    } catch (_) {
      return 'monthly';
    }
  }

  bool get paywallShowAnnualSavings {
    try {
      return _remoteConfig.getBool('paywall_show_annual_savings');
    } catch (_) {
      return true;
    }
  }

  int get rescueNotificationDays {
    try {
      return _remoteConfig.getInt('rescue_notification_days');
    } catch (_) {
      return 3;
    }
  }

  int get maxReviewNoteChars {
    try {
      return _remoteConfig.getInt('max_review_note_chars');
    } catch (_) {
      return 300;
    }
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/unit/shared/services/remote_config_service_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/shared/services/remote_config_service.dart test/unit/shared/services/remote_config_service_test.dart
git commit -m "feat(analytics): add RemoteConfigService with typed accessors and defaults"
```

---

### Task 3: CrashlyticsService

**Files:**
- Create: `lib/shared/services/crashlytics_service.dart`
- Create: `test/unit/shared/services/crashlytics_service_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/unit/shared/services/crashlytics_service_test.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/crashlytics_service.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockFirebaseCrashlytics mockCrashlytics;
  late CrashlyticsService service;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    service = CrashlyticsService(mockCrashlytics);
  });

  group('CrashlyticsService', () {
    test('setUserId delega a FirebaseCrashlytics.setUserIdentifier', () async {
      when(() => mockCrashlytics.setUserIdentifier(any()))
          .thenAnswer((_) async {});

      await service.setUserId('uid_123');

      verify(() => mockCrashlytics.setUserIdentifier('uid_123')).called(1);
    });

    test('recordError delega a FirebaseCrashlytics.recordError', () async {
      final exception = Exception('test error');
      final stackTrace = StackTrace.current;
      when(() => mockCrashlytics.recordError(any(), any(), fatal: any(named: 'fatal')))
          .thenAnswer((_) async {});

      await service.recordError(exception, stackTrace);

      verify(() => mockCrashlytics.recordError(exception, stackTrace, fatal: false))
          .called(1);
    });

    test('log delega a FirebaseCrashlytics.log', () async {
      when(() => mockCrashlytics.log(any())).thenAnswer((_) async {});

      await service.log('task completed');

      verify(() => mockCrashlytics.log('task completed')).called(1);
    });

    test('setUserId swallows exceptions', () async {
      when(() => mockCrashlytics.setUserIdentifier(any()))
          .thenThrow(Exception('crashlytics error'));

      expect(() => service.setUserId('uid'), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/shared/services/crashlytics_service_test.dart
```
Resultado esperado: `Error: 'CrashlyticsService' not found`

- [ ] **Step 3: Crear CrashlyticsService**

```dart
// lib/shared/services/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../core/utils/logger.dart';

class CrashlyticsService {
  CrashlyticsService(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> init() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      // Capturar errores de Flutter no manejados
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterFatalError(errorDetails);
      };
    } catch (e, st) {
      AppLogger.error('Crashlytics init failed', e, st);
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid ?? '');
    } catch (e, st) {
      AppLogger.error('Crashlytics setUserId failed', e, st);
    }
  }

  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (e, st) {
      AppLogger.error('Crashlytics recordError failed', e, st);
    }
  }

  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e, st) {
      AppLogger.error('Crashlytics log failed', e, st);
    }
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/unit/shared/services/crashlytics_service_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/shared/services/crashlytics_service.dart test/unit/shared/services/crashlytics_service_test.dart
git commit -m "feat(analytics): add CrashlyticsService with error recording and user identification"
```

---

### Task 4: Strings ARB para Settings

**Files:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`

- [ ] **Step 1: Añadir claves en app_es.arb**

```json
  "settings_title": "Ajustes",
  "@settings_title": { "description": "Settings screen title" },
  "settings_section_account": "Cuenta",
  "@settings_section_account": { "description": "Account settings section" },
  "settings_edit_profile": "Editar perfil",
  "@settings_edit_profile": { "description": "Edit profile option" },
  "settings_change_password": "Cambiar contraseña",
  "@settings_change_password": { "description": "Change password option" },
  "settings_delete_account": "Eliminar cuenta",
  "@settings_delete_account": { "description": "Delete account option" },
  "settings_section_language": "Idioma",
  "@settings_section_language": { "description": "Language settings" },
  "settings_section_notifications": "Notificaciones",
  "@settings_section_notifications": { "description": "Notifications settings" },
  "settings_section_privacy": "Privacidad",
  "@settings_section_privacy": { "description": "Privacy settings section" },
  "settings_phone_visibility": "Visibilidad del teléfono",
  "@settings_phone_visibility": { "description": "Phone visibility option" },
  "settings_section_subscription": "Suscripción",
  "@settings_section_subscription": { "description": "Subscription section" },
  "settings_view_plan": "Ver plan actual",
  "@settings_view_plan": { "description": "View current plan" },
  "settings_restore_purchases": "Restaurar compras",
  "@settings_restore_purchases": { "description": "Restore purchases" },
  "settings_manage_subscription": "Gestionar suscripción",
  "@settings_manage_subscription": { "description": "Manage subscription" },
  "settings_section_home": "Hogar",
  "@settings_section_home": { "description": "Home settings section" },
  "settings_home_settings": "Ajustes del hogar",
  "@settings_home_settings": { "description": "Home settings" },
  "settings_invite_code": "Código de invitación",
  "@settings_invite_code": { "description": "Invite code" },
  "settings_leave_home": "Abandonar hogar",
  "@settings_leave_home": { "description": "Leave home option" },
  "settings_close_home": "Cerrar hogar",
  "@settings_close_home": { "description": "Close home option" },
  "settings_section_about": "Acerca de",
  "@settings_section_about": { "description": "About section" },
  "settings_app_version": "Versión de la app",
  "@settings_app_version": { "description": "App version" },
  "settings_terms": "Términos de uso",
  "@settings_terms": { "description": "Terms of use" },
  "settings_privacy_policy": "Política de privacidad",
  "@settings_privacy_policy": { "description": "Privacy policy" },
  "settings_plan_free": "Plan gratuito",
  "@settings_plan_free": { "description": "Free plan label" },
  "settings_plan_premium": "Plan Premium",
  "@settings_plan_premium": { "description": "Premium plan label" }
```

- [ ] **Step 2: Añadir en app_en.arb**

```json
  "settings_title": "Settings",
  "@settings_title": { "description": "Settings screen title" },
  "settings_section_account": "Account",
  "@settings_section_account": { "description": "Account settings section" },
  "settings_edit_profile": "Edit profile",
  "@settings_edit_profile": { "description": "Edit profile option" },
  "settings_change_password": "Change password",
  "@settings_change_password": { "description": "Change password option" },
  "settings_delete_account": "Delete account",
  "@settings_delete_account": { "description": "Delete account option" },
  "settings_section_language": "Language",
  "@settings_section_language": { "description": "Language settings" },
  "settings_section_notifications": "Notifications",
  "@settings_section_notifications": { "description": "Notifications settings" },
  "settings_section_privacy": "Privacy",
  "@settings_section_privacy": { "description": "Privacy settings section" },
  "settings_phone_visibility": "Phone visibility",
  "@settings_phone_visibility": { "description": "Phone visibility option" },
  "settings_section_subscription": "Subscription",
  "@settings_section_subscription": { "description": "Subscription section" },
  "settings_view_plan": "View current plan",
  "@settings_view_plan": { "description": "View current plan" },
  "settings_restore_purchases": "Restore purchases",
  "@settings_restore_purchases": { "description": "Restore purchases" },
  "settings_manage_subscription": "Manage subscription",
  "@settings_manage_subscription": { "description": "Manage subscription" },
  "settings_section_home": "Home",
  "@settings_section_home": { "description": "Home settings section" },
  "settings_home_settings": "Home settings",
  "@settings_home_settings": { "description": "Home settings" },
  "settings_invite_code": "Invite code",
  "@settings_invite_code": { "description": "Invite code" },
  "settings_leave_home": "Leave home",
  "@settings_leave_home": { "description": "Leave home option" },
  "settings_close_home": "Close home",
  "@settings_close_home": { "description": "Close home option" },
  "settings_section_about": "About",
  "@settings_section_about": { "description": "About section" },
  "settings_app_version": "App version",
  "@settings_app_version": { "description": "App version" },
  "settings_terms": "Terms of use",
  "@settings_terms": { "description": "Terms of use" },
  "settings_privacy_policy": "Privacy policy",
  "@settings_privacy_policy": { "description": "Privacy policy" },
  "settings_plan_free": "Free plan",
  "@settings_plan_free": { "description": "Free plan label" },
  "settings_plan_premium": "Premium plan",
  "@settings_plan_premium": { "description": "Premium plan label" }
```

- [ ] **Step 3: Añadir en app_ro.arb**

```json
  "settings_title": "Setări",
  "@settings_title": { "description": "Settings screen title" },
  "settings_section_account": "Cont",
  "@settings_section_account": { "description": "Account settings section" },
  "settings_edit_profile": "Editează profilul",
  "@settings_edit_profile": { "description": "Edit profile option" },
  "settings_change_password": "Schimbă parola",
  "@settings_change_password": { "description": "Change password option" },
  "settings_delete_account": "Șterge contul",
  "@settings_delete_account": { "description": "Delete account option" },
  "settings_section_language": "Limbă",
  "@settings_section_language": { "description": "Language settings" },
  "settings_section_notifications": "Notificări",
  "@settings_section_notifications": { "description": "Notifications settings" },
  "settings_section_privacy": "Confidențialitate",
  "@settings_section_privacy": { "description": "Privacy settings section" },
  "settings_phone_visibility": "Vizibilitatea telefonului",
  "@settings_phone_visibility": { "description": "Phone visibility option" },
  "settings_section_subscription": "Abonament",
  "@settings_section_subscription": { "description": "Subscription section" },
  "settings_view_plan": "Vezi planul curent",
  "@settings_view_plan": { "description": "View current plan" },
  "settings_restore_purchases": "Restaurează achizițiile",
  "@settings_restore_purchases": { "description": "Restore purchases" },
  "settings_manage_subscription": "Gestionează abonamentul",
  "@settings_manage_subscription": { "description": "Manage subscription" },
  "settings_section_home": "Acasă",
  "@settings_section_home": { "description": "Home settings section" },
  "settings_home_settings": "Setări casă",
  "@settings_home_settings": { "description": "Home settings" },
  "settings_invite_code": "Cod de invitație",
  "@settings_invite_code": { "description": "Invite code" },
  "settings_leave_home": "Părăsește casa",
  "@settings_leave_home": { "description": "Leave home option" },
  "settings_close_home": "Închide casa",
  "@settings_close_home": { "description": "Close home option" },
  "settings_section_about": "Despre",
  "@settings_section_about": { "description": "About section" },
  "settings_app_version": "Versiunea aplicației",
  "@settings_app_version": { "description": "App version" },
  "settings_terms": "Termeni de utilizare",
  "@settings_terms": { "description": "Terms of use" },
  "settings_privacy_policy": "Politica de confidențialitate",
  "@settings_privacy_policy": { "description": "Privacy policy" },
  "settings_plan_free": "Plan gratuit",
  "@settings_plan_free": { "description": "Free plan label" },
  "settings_plan_premium": "Plan Premium",
  "@settings_plan_premium": { "description": "Premium plan label" }
```

- [ ] **Step 4: Regenerar**

```bash
flutter gen-l10n
```

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(settings): add settings ARB strings for all 3 locales"
```

---

### Task 5: SettingsScreen

**Files:**
- Create: `lib/features/settings/presentation/settings_screen.dart`
- Create: `test/ui/features/settings/settings_screen_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/ui/features/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/settings/presentation/settings_screen.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap({SubscriptionState? subscription}) => ProviderScope(
      overrides: [
        if (subscription != null)
          subscriptionStateProvider.overrideWith((ref) => subscription),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );

void main() {
  testWidgets('SettingsScreen renderiza sección Cuenta', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_account')), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Suscripción', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_subscription')), findsOneWidget);
  });

  testWidgets('SettingsScreen muestra "Plan Premium" cuando hay Premium activo', (tester) async {
    await tester.pumpWidget(_wrap(
      subscription: const SubscriptionState.active(
        plan: 'monthly',
        endsAt: DateTime(2027, 1, 1),
        autoRenew: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subscription_status_label')), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Acerca de', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/ui/features/settings/settings_screen_test.dart
```
Resultado esperado: `Error: 'SettingsScreen' not found`

- [ ] **Step 3: Crear SettingsScreen**

Crear directorio: `lib/features/settings/presentation/`

```dart
// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/application/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool _isPremium(SubscriptionState state) {
    return state.when(
      free: () => false,
      active: (_, __, ___) => true,
      cancelledPendingEnd: (_, __) => true,
      rescue: (_, __, ___) => true,
      expiredFree: () => false,
      restorable: (_) => false,
      purged: () => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = _isPremium(ref.watch(subscriptionStateProvider));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        children: [
          // ── Cuenta ──────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_account'), title: l10n.settings_section_account),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settings_edit_profile),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settings_change_password),
            onTap: () {/* TODO: change password flow */},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.settings_delete_account),
            onTap: () {/* TODO: delete account confirmation */},
          ),
          const Divider(),

          // ── Idioma ───────────────────────────────────────────────────
          ListTile(
            key: const Key('settings_language'),
            leading: const Icon(Icons.language),
            title: Text(l10n.settings_section_language),
            onTap: () {/* TODO: language selector */},
          ),
          const Divider(),

          // ── Notificaciones ───────────────────────────────────────────
          ListTile(
            key: const Key('settings_notifications'),
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settings_section_notifications),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          const Divider(),

          // ── Privacidad ────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_section_privacy),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(l10n.settings_phone_visibility),
            onTap: () {/* TODO: phone visibility setting */},
          ),
          const Divider(),

          // ── Suscripción ───────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_subscription'), title: l10n.settings_section_subscription),
          ListTile(
            key: const Key('subscription_status_label'),
            leading: Icon(
              isPremium ? Icons.star : Icons.star_border,
              color: isPremium ? Colors.amber : null,
            ),
            title: Text(isPremium ? l10n.settings_plan_premium : l10n.settings_plan_free),
            onTap: () => context.push(AppRoutes.subscription),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l10n.settings_restore_purchases),
            onTap: () => context.push(AppRoutes.subscription),
          ),
          const Divider(),

          // ── Hogar ─────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_section_home),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.settings_home_settings),
            onTap: () => context.push(AppRoutes.homeSettings),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text(l10n.settings_invite_code),
            onTap: () {/* TODO: show invite code */},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: Text(l10n.settings_leave_home,
                style: const TextStyle(color: Colors.red)),
            onTap: () {/* TODO: leave home confirmation */},
          ),
          const Divider(),

          // ── Acerca de ─────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_about'), title: l10n.settings_section_about),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (ctx, snap) {
              final version = snap.data?.version ?? '—';
              final build = snap.data?.buildNumber ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settings_app_version),
                subtitle: Text('$version ($build)'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settings_terms),
            onTap: () {/* TODO: open terms URL */},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settings_privacy_policy),
            onTap: () {/* TODO: open privacy policy URL */},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
```

**Nota:** `SettingsScreen` usa `package_info_plus`. Verificar si está en pubspec.yaml; si no, añadir:
```yaml
  package_info_plus: ^8.0.0
```
y ejecutar `flutter pub get`.

- [ ] **Step 4: Añadir ruta settings en app.dart**

La ruta `/settings` ya está definida en `AppRoutes`. Añadir el import e importar la pantalla en `lib/app.dart`:

```dart
import 'features/settings/presentation/settings_screen.dart';

// Añadir dentro del router (puede existir ya un placeholder — reemplazarlo):
GoRoute(
  path: AppRoutes.settings,
  builder: (_, __) => const SettingsScreen(),
),
```

- [ ] **Step 5: Confirmar que los tests pasan**

```bash
flutter test test/ui/features/settings/settings_screen_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 6: Generar golden**

Añadir al final del archivo:
```dart
  testWidgets('golden: SettingsScreen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
```

```bash
flutter test test/ui/features/settings/settings_screen_test.dart --update-goldens
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/ test/ui/features/settings/ lib/app.dart
git commit -m "feat(settings): add SettingsScreen with all sections and golden test"
```

---

### Task 6: Inicializar servicios en main_prod.dart y main_dev.dart

**Files:**
- Modify: `lib/main_prod.dart`
- Modify: `lib/main_dev.dart`

- [ ] **Step 1: Actualizar main_prod.dart**

Reemplazar el contenido de `lib/main_prod.dart`:

```dart
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar observabilidad antes de runApp
  final crashlyticsService = CrashlyticsService(FirebaseCrashlytics.instance);
  await crashlyticsService.init();

  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.init();

  // AnalyticsService disponible pero no requiere init async
  final analyticsService = AnalyticsService(FirebaseAnalytics.instance);

  // Capturar errores no manejados de Dart
  runZonedGuarded(
    () => runApp(ProviderScope(
      overrides: [
        // Exponer los servicios como providers si se necesitan globalmente
        // (añadir providers en shared/services si se requiere)
      ],
      child: const TokaApp(),
    )),
    (error, stack) {
      crashlyticsService.recordError(error, stack, fatal: true);
    },
  );
}
```

- [ ] **Step 2: Leer main_dev.dart para ver su estructura**

```bash
cat lib/main_dev.dart
```

- [ ] **Step 3: Actualizar main_dev.dart con inicialización similar**

Añadir inicialización de Crashlytics y RemoteConfig en `main_dev.dart`. En dev, Crashlytics puede estar en modo test (no reporta a producción).

```dart
// Al inicio de main() en main_dev.dart, después de Firebase.initializeApp:
// Crashlytics en dev: solo log local, no envía a producción
final crashlyticsService = CrashlyticsService(FirebaseCrashlytics.instance);
// No llamar crashlyticsService.init() en dev para no enviar datos reales
```

- [ ] **Step 4: Verificar compilación**

```bash
flutter analyze lib/main_prod.dart lib/main_dev.dart
```
Resultado esperado: sin errores.

- [ ] **Step 5: Commit**

```bash
git add lib/main_prod.dart lib/main_dev.dart
git commit -m "feat(analytics): initialize Crashlytics and RemoteConfig in main_prod"
```

---

### Task 7: Ejecutar suite completa y verificar

- [ ] **Step 1: Ejecutar todos los tests**

```bash
flutter test test/unit/ test/integration/ test/ui/
```
Resultado esperado: todos pasan.

- [ ] **Step 2: Análisis estático**

```bash
flutter analyze
```
Resultado esperado: sin errores ni warnings.

- [ ] **Step 3: Compilar functions**

```bash
cd functions && npm run build
```

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "feat(spec-14): complete settings screen, analytics events, remote config, crashlytics"
```

---

## Pruebas manuales requeridas (Spec-14)

1. **Analítica:** Completar el flujo de registro → ir a Firebase Analytics DebugView en consola Firebase → verificar que aparece el evento `auth_signup_completed`.
2. **Remote Config:** En Firebase Console → Remote Config, cambiar `ad_banner_enabled = false` → forzar fetch en la app (reiniciar) → el banner publicitario desaparece.
3. **Crashlytics:** Añadir temporalmente un `throw Exception('test crash')` en un botón → abrirlo → verificar en Crashlytics Dashboard.
4. **Pantalla de ajustes:** Navegar desde la app a `/settings` → verificar que todas las secciones (Cuenta, Idioma, Notificaciones, Privacidad, Suscripción, Hogar, Acerca de) aparecen sin errores.
5. **Idioma en ajustes:** Ajustes → Idioma → cambiar a "English" → toda la app cambia al inglés.
6. **Estado Premium en ajustes:** Con plan Premium activo → sección Suscripción muestra "Plan Premium" con estrella dorada. Con plan Free → muestra "Plan gratuito".
