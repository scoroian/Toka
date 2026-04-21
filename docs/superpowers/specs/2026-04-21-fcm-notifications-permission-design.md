# Spec: Permiso de notificaciones FCM (Android 13+ / iOS)

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Crítica (BUG-09, no llegan pushes en Android 13+)

---

## Contexto

Android 13 (API 33) introdujo el permiso runtime `POST_NOTIFICATIONS`. Apps que no lo solicitan explícitamente **no pueden mostrar notificaciones** al usuario, aunque FCM siga entregándolas al dispositivo. En iOS es similar con `requestPermission()` del APNs.

Durante QA 2026-04-20 (BUG-09, crítico) se confirmó que Toka:

- **Nunca llama a `FirebaseMessaging.instance.requestPermission()`.**
- Guarda el `fcmToken` del dispositivo en `users/{uid}/tokens/{tokenId}`, así que el backend envía, pero las push caen en silencio.
- La pantalla Ajustes → Notificaciones muestra toggles que afectan a `users/{uid}.notificationPrefs` pero nunca comprueba el permiso del sistema.

Resultado: los usuarios creen que las notificaciones están activas (porque el toggle está verde) cuando en realidad el SO las bloquea.

---

## Decisiones clave

- **Solicitamos permiso al final del onboarding**, no en `main()`. Pedirlo en arranque frío es una mala práctica (el usuario rechaza por inercia antes de entender el valor).
- **Rationale screen** previa al prompt del sistema: pantalla corta explicando por qué Toka necesita permiso. Se muestra **una sola vez** (persistida en `SharedPreferences` con key `notif_rationale_shown_v1`).
- Si el usuario **deniega**, en Ajustes → Notificaciones los toggles aparecen deshabilitados y con un banner "Activa las notificaciones en los Ajustes del sistema" + botón `AppSettings.openAppSettings()` (paquete `app_settings`).
- **Sincronizamos las `notificationPrefs`** de Firestore con el estado real del permiso al volver al foreground (AppLifecycleState.resumed): si el sistema bloquea, reducimos `notificationPrefs.masterEnabled = false` en Firestore para que el backend no gaste pushes.

---

## Cambios en Android

### `AndroidManifest.xml`

Añadir el permiso runtime (ya implícito en `targetSdk >= 33` pero lo declaramos explícitamente):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

No se toca `minSdkVersion` (≥21 actual). En API 32 y anteriores, `requestPermission()` devuelve `authorized` sin mostrar diálogo — compatible.

---

## Cambios en cliente

### 1. Servicio central

Ampliar [lib/features/notifications/application/fcm_token_service.dart](lib/features/notifications/application/fcm_token_service.dart) con:

```dart
Future<NotificationAuthorizationStatus> requestPermission({bool provisional = false});
Future<NotificationAuthorizationStatus> currentStatus();
```

donde `NotificationAuthorizationStatus ∈ { authorized, denied, notDetermined, provisional }`. Wrapper sobre `FirebaseMessaging.instance.requestPermission(alert:true, badge:true, sound:true)`.

### 2. Nueva pantalla `NotificationRationaleScreen`

Ubicación: `lib/features/onboarding/presentation/notification_rationale_screen.dart`.

Contenido:

- Ilustración corta (`Icon(Icons.notifications_active)` temporal hasta que diseño entregue SVG).
- Título (i18n `notifRationaleTitle`): "Toka te avisará sólo de lo importante".
- Cuerpo: 3 bullets (nueva tarea asignada / turno cambiado / valoración recibida).
- Botón primario "Activar notificaciones" → llama a `fcmTokenService.requestPermission()`.
- Botón secundario "Ahora no" → persiste `notif_rationale_shown_v1 = true` y navega al siguiente paso.

Independientemente del resultado del prompt:

1. Persistir `notif_rationale_shown_v1 = true`.
2. Escribir en `users/{uid}.notificationPrefs.systemAuthorized = <bool>`.
3. Continuar con el flujo.

### 3. Inserción en el flujo

El onboarding actual termina con la selección/creación de hogar. Añadir un paso final **inmediatamente después** del primer hogar listo, sólo si:

- `notif_rationale_shown_v1 != true` en `SharedPreferences` **o**
- `fcmTokenService.currentStatus() == notDetermined`.

Si el usuario reinstala la app (SharedPreferences reset), volverá a ver la pantalla — es el comportamiento deseado.

### 4. Observer de ciclo de vida

En [lib/app.dart](lib/app.dart) (o donde viva el `MaterialApp`), registrar un `WidgetsBindingObserver` que en `didChangeAppLifecycleState(resumed)`:

1. Llama a `fcmTokenService.currentStatus()`.
2. Si devuelve `denied` y `notificationPrefs.systemAuthorized == true` en local → actualiza Firestore `users/{uid}.notificationPrefs.systemAuthorized = false`.
3. Si `authorized` y era `false` → vuelve a `true`.

Esto evita drift entre "permiso del SO" y "preferencia del servidor".

### 5. Ajustes de notificaciones — rework parcial

En [lib/features/notifications/application/notification_settings_view_model.dart](lib/features/notifications/application/notification_settings_view_model.dart) añadir al estado `systemAuthorized: bool`.

UI en la pantalla de notificaciones:

- Si `systemAuthorized == false`, todos los switches aparecen deshabilitados y en la parte superior un `MaterialBanner`:
  > **Notificaciones bloqueadas por el sistema.** Activa los permisos en Ajustes de Android para recibir avisos de Toka.
  >
  > `[ Abrir ajustes ]`
- El botón llama a `AppSettings.openNotificationSettings()` (paquete `app_settings` — ya lo usamos en otros flujos; si no, añadir a `pubspec.yaml`).

---

## Backend

Sin cambios. El backend ya no envía pushes si `users/{uid}.notificationPrefs.masterEnabled = false`. Sólo nos apoyamos en que el nuevo flujo de cliente mantenga el campo sincronizado.

Opcional (fuera de alcance en este spec pero útil documentar): en `functions/src/notifications/` se podría añadir un lector que, al registrar un token, verifique que `systemAuthorized == true` antes de considerar al usuario "notificable".

---

## i18n

Nuevas claves ARB:

- `notifRationaleTitle`
- `notifRationaleBullet1` / `Bullet2` / `Bullet3`
- `notifRationaleCtaEnable`
- `notifRationaleCtaLater`
- `notifSystemBlockedBanner`
- `notifSystemBlockedAction` — "Abrir ajustes"

---

## Tests

- `fcm_token_service_test.dart`: mockear `FirebaseMessaging` y verificar que `requestPermission` devuelve el status y lo propaga.
- `notification_rationale_screen_test.dart`: la pantalla invoca el servicio y navega al completar.
- `notification_settings_view_model_test.dart`: cuando `systemAuthorized=false`, los toggles quedan en estado `disabled`.
- Integración UI: golden de la pantalla rationale en light/dark.

---

## Fuera de alcance

- Notificaciones provisional (iOS) — no las pedimos, queremos consentimiento explícito.
- Canal de notificación avanzado en Android (Notification Channels por tipo) — actualmente todo va a un único canal `default`; spec futura si se necesitan prioridades por tipo.
- Migración de usuarios existentes que ya tienen `notificationPrefs` sin `systemAuthorized`: al primer launch tras update, el observer los sincroniza automáticamente.
