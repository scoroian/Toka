# Diseño — Hallazgo #04: mapeo de errores al unirse a un hogar

> Lote "UX Hallazgos 2026-06-25", prompt `04`. Depende de `01` (✅, introduce
> `NoAccountSlotsException` / `no-account-slots`).

## Problema

Al unirse a un hogar por código, el cliente mapea **cualquier**
`failed-precondition` a `MaxMembersReachedException` ("hogar lleno") y, según la
entrada, el **mismo motivo** muestra mensajes distintos:

| Motivo backend (`joinHomeByCode`) | Selector multi‑hogar | Onboarding |
|---|---|---|
| `not-found` (código inválido) | "Código inválido" | "Código de invitación inválido" |
| `deadline-exceeded` (expirado) | "El código ha expirado" | "El código de invitación ha expirado" |
| `failed-precondition` + `free_limit_members` (hogar lleno) | "Tu plan Free permite hasta 3 miembros…" | ❌ **"Algo salió mal"** (genérico) |
| `resource-exhausted` + `no-account-slots` (sin plazas de cuenta) | ✓ (prompt 01) | ✓ (prompt 01) |
| `resource-exhausted` + `too-many-join-attempts` (rate‑limit) | "Demasiados intentos" | "Demasiados intentos" |

Causas raíz:

1. `HomeCreationRepositoryImpl.joinHome` (camino onboarding) solo mapea
   `not-found`/`deadline-exceeded` y **relanza el resto en crudo**.
2. `OnboardingNotifier.joinHome` no tiene rama para `failed-precondition` →
   cae en `unexpected_error` → "Algo salió mal".
3. Cada entrada tiene su **propia tabla** de mensajes con textos diferentes.

## Objetivo

Mapear cada motivo **por su `code` específico** (no por la categoría genérica) y
**unificar** los mensajes entre selector y onboarding en **una sola fuente de
verdad**.

## Diseño

Dos archivos pequeños en `lib/features/homes/application/` (la feature `homes`
es dueña de la lógica de "unirse"; `onboarding` la reutiliza):

### 1. `join_home_error.dart` (sin l10n — lógica pura, testeable aislada)

```dart
enum JoinHomeError {
  invalidCode, expiredCode, homeFull, noAccountSlots,
  tooManyAttempts, permissionDenied, network, unexpected,
}

/// Fuente de verdad ÚNICA: FirebaseFunctionsException → excepción de dominio.
/// La usan AMBOS repos (HomesRepositoryImpl y HomeCreationRepositoryImpl) para
/// que selector y onboarding produzcan las MISMAS excepciones tipadas.
/// Mapea por el `code` específico; donde el backend reusa un code para dos
/// motivos (`resource-exhausted`), los distingue por el `message`.
Exception mapJoinHomeException(FirebaseFunctionsException e);

/// Clasifica cualquier error de unión (excepción de dominio tipada, FFE sin
/// mapear, SocketException) a un motivo canónico. Para FFE crudo delega en
/// mapJoinHomeException (red de seguridad: nunca cae al genérico ante un motivo
/// conocido aunque un caller no haya pasado por el repo).
JoinHomeError classifyJoinHomeError(Object error);
```

Mapeo `code → excepción`:

- `not-found` → `InvalidInviteCodeException`
- `deadline-exceeded` → `ExpiredInviteCodeException`
- `resource-exhausted` + msg `no-account-slots` → `NoAccountSlotsException`
- `resource-exhausted` (resto, rate‑limit) → `TooManyAttemptsException` (NUEVA)
- `failed-precondition` + msg `free_limit_members` → `MaxMembersReachedException`
- resto → el propio FFE (caller hace `rethrow` → motivo `unexpected`)

`permission-denied` no tiene excepción de dominio (no es un error de negocio del
join): se clasifica a `permissionDenied` directamente.

### 2. `join_home_error_messages.dart` (con l10n)

```dart
/// El ÚNICO mapa motivo → texto. Selector y onboarding lo comparten, así que la
/// paridad de mensajes queda garantizada por construcción.
String joinHomeErrorMessage(JoinHomeError reason, AppLocalizations l10n);
```

### Nueva excepción de dominio

`TooManyAttemptsException` en `core/errors/exceptions.dart` (hoy el rate‑limit
viaja en crudo como FFE y cada UI lo intercepta a mano).

### Cableado

- **Repos** (`HomesRepositoryImpl.joinHome`, `HomeCreationRepositoryImpl.joinHome`):
  `catch (FirebaseFunctionsException e) { final m = mapJoinHomeException(e);
  if (identical(m, e)) rethrow; throw m; }`.
- **Selector** (`home_selector_widget._joinErrorMessage`):
  `joinHomeErrorMessage(classifyJoinHomeError(e), l10n)`.
- **Onboarding provider** (`OnboardingNotifier.joinHome`): `catch (e) { error:
  classifyJoinHomeError(e).name }` (guarda el nombre del enum en `state.error`).
- **Onboarding form** (`home_join_form`): resuelve `widget.error` con
  `joinHomeErrorMessage(JoinHomeError.values.asNameMap()[error]!, l10n)`;
  desconocido → `error_generic`.

## i18n (decisión: namespace nuevo `join_error_*`, es/en/ro)

| Clave | Origen del texto |
|---|---|
| `join_error_invalid_code` | reusa texto de `onboarding_error_invalid_invite` |
| `join_error_expired_code` | reusa `onboarding_error_expired_invite` |
| `join_error_home_full` | **NUEVO neutral** (tier‑agnóstico; el copy tiered es del prompt 05) |
| `join_error_no_account_slots` | reusa `onboarding_error_no_account_slots` |
| `join_error_too_many_attempts` | reusa `error_too_many_attempts` |
| `join_error_permission_denied` | reusa `onboarding_error_permission_denied` |
| `join_error_network` | reusa `onboarding_error_network` |
| `join_error_generic` | reusa `error_generic` |

Copy neutral "hogar lleno":
- es: "Este hogar ya está completo. Pídele a un administrador que amplíe el plan o libere una plaza."
- en: "This home is already full. Ask an admin to upgrade the plan or free up a spot."
- ro: "Această casă este deja plină. Roagă un administrator să extindă planul sau să elibereze un loc."

Se eliminan las claves huérfanas tras el cambio (solo usadas en estos 2
sitios): `homes_error_invalid_code`, `homes_error_expired_code`,
`homes_error_no_account_slots`, `onboarding_error_invalid_invite`,
`onboarding_error_expired_invite`, `onboarding_error_no_account_slots`,
`onboarding_error_network`, `onboarding_error_permission_denied`,
`onboarding_error_unexpected`. (`error_generic`, `error_too_many_attempts` y
`free_limit_members_reached` se conservan: se reutilizan en otras pantallas.)

## Pruebas

- **Unit** `join_home_error_test.dart`: `mapJoinHomeException` por cada code;
  `classifyJoinHomeError` por cada excepción tipada + FFE crudo + SocketException;
  `joinHomeErrorMessage` cubre todos los `JoinHomeError` (ninguno cae al genérico).
- **Paridad**: para cada escenario backend, el motivo resuelto por el camino del
  selector (excepción de dominio) == el del onboarding (FFE crudo → classify) →
  mismo mensaje.
- Se actualizan: `home_creation_integration_test`, `onboarding_provider_test`,
  `onboarding_view_model_test`, `onboarding_flow_test`, `home_creation_repository_test`.
- **Gates**: `flutter analyze` limpio; `flutter test test/unit` verde.
- Verificación en dispositivo (MI_9 + emulador, Firebase real): **segunda pasada**.

## Fuera de alcance

- Copy tiered de "hogar lleno" (prompt 05).
- Tocar el backend (`joinHomeByCode` ya emite los codes correctos).
