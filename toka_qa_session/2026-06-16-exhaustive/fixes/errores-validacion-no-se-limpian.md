# §6 — 🟡 Errores de validación no se limpian al corregir el campo

Estado: **RESUELTO** · Verificado end-to-end en 2 dispositivos (login) + cobertura de tests para los 5 formularios · Fecha: 2026-06-17

## Bug

Varios formularios mostraban el error de validación en rojo y **no lo limpiaban**
aunque el usuario corrigiera el campo; el error persistía hasta el siguiente
submit. Casos reportados:

- **Login** (`EmailAuthForm`): email inválido → escribir un email válido y el
  error "Introduce un email válido" seguía.
- **Onboarding perfil** (`ProfileStepV2`): "El apodo es obligatorio" seguía tras
  escribir un apodo.
- **Unirse por código** (`HomeJoinForm`): "Código de invitación inválido" seguía
  tras corregir el código.

## Causa raíz

Había **dos mecanismos distintos** detrás del mismo síntoma:

### Causa 1 — Ningún `Form` definía `autovalidateMode` (todos los casos de validación local)

En Flutter, un `Form` sin `autovalidateMode` queda en `AutovalidateMode.disabled`.
En ese modo la validación **solo** ocurre cuando se llama a
`_formKey.currentState!.validate()` (en el submit). Tras ese `validate()`, el
`errorText` del `FormField` queda fijado y **no se reevalúa al teclear**, porque
en `disabled` el `build()` del campo no vuelve a validar. Resultado: el error en
rojo se queda hasta el siguiente submit aunque el valor ya sea válido.

Confirmado: **ningún** `Form` del proyecto usaba `autovalidateMode`
(`grep -r autovalidateMode lib/` → 0 resultados antes del fix).

### Causa 2 — Error de servidor del view model en "Unirse por código" (mecanismo aparte)

En `HomeJoinForm` el mensaje "Código de invitación inválido" (y `expired_invite`,
`network_error`, `no_slots`, etc.) **no** es un `validator` del campo: es estado
del `OnboardingNotifier` (`OnboardingState.error`) que se pinta en un `Text`
independiente bajo el campo. Por tanto `autovalidateMode` **no** lo limpia: aunque
el campo se revalide, el `Text` del error de servidor sigue ahí porque el estado
del view model no cambia hasta el siguiente submit (que hace `error: null` →
nuevo error). Hacía falta limpiar ese estado al editar el campo.

## Casos relacionados detectados (no reportados en QA)

- **`forgot_password_screen.dart`** (`_FormView`): mismo patrón exacto (validator
  de email sin `autovalidateMode`). Lo arreglé también.
- **`HomeChoiceStepV2`** (crear hogar): el `Form` del nombre tampoco tenía
  `autovalidateMode`, y el error de servidor `no_slots` se pintaba aparte (mismo
  caso que el de unirse). Arreglado con `autovalidateMode` + limpieza de error.
- `edit_profile_screen_v2.dart` se revisó: **no** usa `Form`/`validator` (solo
  `onChanged`), así que no está afectado.

## Fix

### Cliente — `autovalidateMode` en todos los formularios afectados

Añadido `autovalidateMode: AutovalidateMode.onUserInteraction` al `Form` de:

- `lib/features/auth/presentation/widgets/email_auth_form.dart` (login + registro)
- `lib/features/auth/presentation/forgot_password_screen.dart`
- `lib/features/onboarding/presentation/steps/skins/profile_step_v2.dart`
- `lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart` (crear hogar)
- `lib/features/onboarding/presentation/widgets/home_join_form.dart` (longitud del código)

Con `onUserInteraction`, tras el primer submit (que marca el campo), cada cambio
del usuario revalida el campo en `build()` y el error desaparece en cuanto el
valor pasa a ser válido — sin reenviar.

### Cliente — limpieza del error de servidor al editar (unirse + crear)

Nuevo método `clearError()` en el view model del onboarding y cableado de un
callback opcional `onClearError` hasta los campos:

- `OnboardingNotifier.clearError()` (`onboarding_provider.dart`): `if (state.error != null) state = state.copyWith(error: null)`.
- `OnboardingViewModel.clearError()` (contrato + impl que delega en `_inner`) en `onboarding_view_model.dart`.
- `onboarding_flow_screen.dart` pasa `onClearError: vm.clearError` a `HomeChoiceStep`.
- `HomeChoiceStep` (wrapper) → `HomeChoiceStepV2` → `HomeJoinForm` reenvían el callback.
- El campo del código (`HomeJoinForm`) y el del nombre (`HomeChoiceStepV2`) llaman
  `onClearError` en su `onChanged` (solo si `widget.error != null`), de modo que al
  empezar a corregir desaparece el "Código de invitación inválido" / "no_slots".

El error de servidor del **login** (credenciales inválidas, etc.) ya se gestionaba
bien: se muestra por `SnackBar` y se limpia con `vm.clearError()` en el `ref.listen`,
así que no requería cambios.

## Tests añadidos (fallan antes del fix, pasan después)

- **Unit** `test/unit/features/onboarding/onboarding_view_model_test.dart`:
  - `clearError clears the inner error state`
  - `clearError is a no-op when there is no error`
- **Widget** `test/ui/features/auth/login_screen_test.dart`:
  - `email error clears when the field becomes valid without resubmitting`
- **Widget** `test/ui/features/auth/forgot_password_screen_test.dart`:
  - `email validation error clears after correcting the email`
- **Widget** `test/ui/features/onboarding/onboarding_flow_test.dart`:
  - `ProfileStepV2 limpia el error del apodo al escribir uno válido` (probado
    sobre `ProfileStepV2` aislado, no a través del flow, para no depender de la
    animación del `PageView`).
  - `HomeJoinForm limpia el error de longitud al completar el código`
  - `HomeJoinForm limpia el error de servidor al editar el código` (host con estado
    que simula el view model: `onClearError` pone `error=null`).

`flutter analyze lib/features/auth lib/features/onboarding test/...` → **No issues**.
Los 7 tests nuevos pasan. Sin regresiones: el archivo `onboarding_flow_test.dart`
tenía 9 fallos pre-existentes (tests que usan el flow completo con `PageView` +
goldens, que hacen timeout de `pumpAndSettle` en este entorno) — verificado por
baseline con `git stash` que esos mismos 9 fallan **igual** sin mis cambios (4
pasan / 9 fallan antes; 7 pasan / 9 fallan después, los 3 extra son míos).

## Verificación en dispositivo

APK debug (`flutter build apk --debug`, tras `pub get` en **Windows** para
restaurar las rutas de paquetes; ver nota abajo) instalado en MI_9 físico
(`43340fd2`) y emulador (`emulator-5554`), ambos contra prod `toka-dd241`.

**Caso login, end-to-end en AMBOS dispositivos:**
1. Cerrar sesión → pantalla de login.
2. Escribir email inválido (`correo-invalido`) + submit → aparece "Introduce un
   email válido" con el campo en rojo. ✔
3. Corregir el email a `correo-invalido@toka.app` (válido) → el error **desaparece
   al teclear**, sin reenviar, y el borde del campo vuelve a la normalidad. ✔
   (En MI_9 con entrada carácter-a-carácter por el teclado Facemoji; en emulador
   con Gboard. Mismo resultado.)

Los demás casos (forgot-password, apodo del onboarding, longitud del código)
comparten el mismo mecanismo `autovalidateMode` ya verificado en dispositivo vía
login; el error de servidor al unirse está cubierto por los tests de widget+unit.
Reproducir los pasos de onboarding/join en dispositivo exige una cuenta a medio
onboarding (reset de flags `onboardingCompleted`), por lo que se cubrieron por
tests en lugar de en dispositivo.

Estado tras la verificación: ambos dispositivos re-logueados como N2 (estado
restaurado), capturas borradas, rutas de paquetes WSL restauradas con
`flutter pub get`.

## Notas / hallazgos durante el trabajo

- **[BUILD] Trampa WSL↔Windows (no es bug de la app):** el primer
  `flutter.bat build apk` falló con cientos de `Error when reading
  '/home/scoroian/.pub-cache/...'` y un confuso "switch on dynamic not
  exhaustive" en `history_view_model.dart`. **Causa:** el
  `.dart_tool/package_config.json` apuntaba a rutas Linux (de correr
  `flutter` en WSL); el Flutter de Windows no puede leerlas y los tipos de los
  paquetes (incl. la sealed class `TaskEvent`) quedan sin resolver → `e` se
  infiere `dynamic`. **Solución:** ejecutar `flutter.bat pub get` en **Windows**
  antes del build (y `flutter pub get` en WSL después, para que el tooling WSL
  siga funcionando). Esto está en el §0 del FIX_PROMPTS; lo había omitido en el
  primer intento. Conviene tenerlo siempre presente al alternar WSL/Windows.
- El working tree tenía ~250 `.dart` marcados como modificados, pero `git diff -w`
  está vacío para casi todos → es **ruido de line-endings (CRLF↔LF)**. Solo ~13
  archivos (WIP de §4/§5: homes/`current_home_provider`, `dashboard_provider`,
  subscription, today) tienen cambio de contenido real; ninguno relacionado con
  este fix.
